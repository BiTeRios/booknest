import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

/// Загрузка файла (обложки книги) на POST /files — multipart, поле «file».
/// Сервер отвечает 201 с ОТНОСИТЕЛЬНЫМ url вида «/files/7»; его и хранит книга,
/// а показ — Image.network('$apiBase$url').
class FileApi {
  FileApi(this.baseUrl, this.tokens, {this.onUnauthorized});

  final String baseUrl;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  /// Файл передаётся дольше JSON — таймаут щедрее.
  static const _timeout = Duration(seconds: 20);

  Future<Result<String>> upload(String path) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/files'))
        ..headers['Authorization'] = 'Bearer ${await tokens.read() ?? ''}'
        ..files.add(await http.MultipartFile.fromPath('file', path));
      // timeout на send(): иначе сервер, замёрзший ВО ВРЕМЯ передачи, не истечёт
      final res = await http.Response.fromStream(
        await req.send().timeout(_timeout),
      );
      if (res.statusCode == 401) {
        await tokens.clear();
        onUnauthorized?.call();
        return const Err('Сессия истекла — войдите снова');
      }
      if (res.statusCode != 201) return Err(apiMessage(res)); // напр. > 5 МБ
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Ok(data['url'] as String);
    } on SocketException {
      return const Err('Нет сети — повторите попытку', isNetwork: true);
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку', isNetwork: true);
    } on TimeoutException {
      return const Err('Сервер не отвечает', isNetwork: true);
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}
