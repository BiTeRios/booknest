import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'app_user.dart';
import 'result.dart';
import 'token_store.dart';

/// Вход и регистрация по контракту backend-а; token уходит в TokenStore.
class AuthApi {
  AuthApi(this.baseUrl, this.tokens, {http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client; // в тестах — MockClient

  static const _timeout = Duration(seconds: 8);

  Future<Result<AppUser>> register(
    String email,
    String password,
    String name,
  ) => _post('/auth/register', {
    'email': email,
    'password': password,
    'name': name,
  });

  Future<Result<AppUser>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<void> logout() => tokens.clear();

  /// register и login разнятся лишь путём и телом — один _post на оба.
  Future<Result<AppUser>> _post(String path, Map<String, Object?> body) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout); // без timeout зависший сервер = вечный spinner
      if (res.statusCode != 200 && res.statusCode != 201) {
        return Err(apiMessage(res)); // слой 2: 400 / 401 / 409 из конверта
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await tokens.save(data['token'] as String, user); // login → setString
      return Ok(user);
    } on SocketException {
      return const Err('Нет сети — повторите попытку', isNetwork: true);
    } on TimeoutException {
      return const Err('Сервер не отвечает', isNetwork: true);
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку', isNetwork: true);
    } on FormatException {
      return const Err('Ответ не тот, что обещан'); // слой 3: тело-сюрприз
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}
