import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

/// Общий скелет запроса к backend-у для всех хранилищ: Bearer token, timeout,
/// вердикт по статусу и три слоя отказа, каждый на своём месте —
///   1) упала дорога (нет сети, таймаут) — исключение, ловится по типу;
///   2) дурная весть сервера (400/404/…) — не бросает, читается из statusCode
///      и переводится из конверта ошибки через apiMessage;
///   3) тело-сюрприз (не JSON, не та форма) — FormatException/TypeError.
/// Все ветки стекаются в Err(msg): модели и экраны знают только Result.
class ApiClient {
  ApiClient(this.baseUrl, this.tokens, {this.onUnauthorized});

  final String baseUrl;
  final TokenStore tokens;

  /// Что делать, когда сервер сказал 401, решает корень композиции (main):
  /// хранилище не импортирует router.
  final void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 8);

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await tokens.read() ?? ''}',
  };

  /// 401 = пропуск умер: token выбрасывается, корень уводит на вход.
  Future<String> _sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }

  /// [okStatus] — хороший статус этого глагола (200, 201 или 204);
  /// [parse] превращает декодированное тело в значение (для 204 тела нет).
  Future<Result<T>> send<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required int okStatus,
    required T Function(Object? json) parse,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final headers = await _headers();
      final encoded = body == null ? null : jsonEncode(body);
      final res = await switch (method) {
        'GET' => http.get(uri, headers: headers),
        'POST' => http.post(uri, headers: headers, body: encoded),
        'PUT' => http.put(uri, headers: headers, body: encoded),
        'DELETE' => http.delete(uri, headers: headers),
        _ => throw ArgumentError.value(method, 'method'),
      }.timeout(_timeout); // timeout на КАЖДЫЙ запрос: иначе вечный spinner

      if (res.statusCode == 401) return Err(await _sessionDied());
      if (res.statusCode != okStatus) return Err(apiMessage(res)); // слой 2
      // 204 — пустое тело: jsonDecode('') бросил бы FormatException.
      return Ok(parse(res.statusCode == 204 ? null : jsonDecode(res.body)));
    } on SocketException {
      return const Err('Нет сети — повторите попытку'); // слой 1
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан'); // слой 3
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }

  /// Список из пагинированного конверта {items, page, limit, total}.
  static List<T> items<T>(
    Object? json,
    T Function(Map<String, dynamic>) fromJson,
  ) => ((json as Map<String, dynamic>)['items'] as List)
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList();
}
