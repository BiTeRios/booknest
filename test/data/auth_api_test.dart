import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:booknest/data/app_user.dart';
import 'package:booknest/data/auth_api.dart';
import 'package:booknest/data/offline_cache.dart';
import 'package:booknest/data/result.dart';
import 'package:booknest/data/token_store.dart';

http.Response json(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  final tokens = TokenStore();
  final cache = OfflineCache();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  AuthApi auth(Future<http.Response> Function(http.Request) handler) => AuthApi(
    'http://api.test',
    tokens,
    cache: cache,
    client: MockClient(handler),
  );

  test('login 200: token и профиль сохранены, пароль — нет', () async {
    late http.Request sent;
    final result = await auth((req) async {
      sent = req;
      return json({
        'token': 'jwt-abc',
        'user': {'id': 1, 'email': 'vitalii@booknest.md', 'name': 'Vitalii'},
      }, 200);
    }).login('vitalii@booknest.md', 'parola123');

    expect(sent.url.path, '/auth/login');
    expect((result as Ok<AppUser>).value.name, 'Vitalii');
    expect(await tokens.read(), 'jwt-abc');
    expect((await tokens.readUser())?.email, 'vitalii@booknest.md');

    // Всё, что приложение записало на диск, — ни следа пароля.
    final prefs = await SharedPreferences.getInstance();
    final onDisk = prefs.getKeys().map((k) => '$k=${prefs.get(k)}').join(';');
    expect(onDisk, isNot(contains('parola123')));
  });

  test('login 401: «Неверный email или пароль», token не появился', () async {
    final result = await auth(
      (_) async => json({
        'error': {'code': 'UNAUTHORIZED', 'message': 'Invalid credentials'},
      }, 401),
    ).login('vitalii@booknest.md', 'wrong-pass');
    expect((result as Err).msg, 'Неверный email или пароль');
    expect(await tokens.read(), isNull);
  });

  test('register 409: e-mail уже занят', () async {
    final result = await auth(
      (_) async => json({
        'error': {'code': 'EMAIL_TAKEN', 'message': 'Email already registered'},
      }, 409),
    ).register('vitalii@booknest.md', 'parola123', 'Vitalii');
    expect((result as Err).msg, 'Аккаунт с этим email уже существует');
  });

  test('logout стирает token И offline-кэш этого пользователя', () async {
    await tokens.save(
      'jwt-abc',
      const AppUser(id: 1, email: 'a@b.md', name: 'A'),
    );
    await cache.putList('books:mine:1:10::', [
      {'id': 1},
    ]);

    await auth((_) async => json(null, 500)).logout();

    expect(await tokens.read(), isNull);
    expect(await tokens.readUser(), isNull);
    expect(await cache.getList('books:mine:1:10::', (j) => j), isNull);
  });
}
