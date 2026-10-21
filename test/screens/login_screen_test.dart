import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:booknest/data/token_store.dart';

import '../support/test_app.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  late List<http.Request> requests;

  /// «Сервер» входа: для пароля parola123 — 200 с токеном, иначе 401.
  final server = MockClient((req) async {
    requests.add(req);
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    if (body['password'] != 'parola123') {
      return http.Response(
        jsonEncode({
          'error': {'code': 'UNAUTHORIZED', 'message': 'Invalid credentials'},
        }),
        401,
      );
    }
    return http.Response(
      jsonEncode({
        'token': 'jwt-abc',
        'user': {'id': 1, 'email': body['email'], 'name': 'Vitalii'},
      }),
      200,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
  });

  Future<TestApp> openLogin(WidgetTester tester) async {
    final app = TestApp(authClient: server);
    await app.start(tester, initialLocation: '/login');
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('пустой submit: ошибки под полями, на сервер не идёт', (
    tester,
  ) async {
    await openLogin(tester);
    expect(find.text('BookNest'), findsOneWidget);

    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Введите e-mail'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
    expect(requests, isEmpty); // невалидная форма не тратит запрос
  });

  testWidgets('неверный формат e-mail и короткий пароль', (tester) async {
    await openLogin(tester);
    await tester.enterText(field('E-mail'), 'vitalii@booknest');
    await tester.enterText(field('Пароль'), '123');
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Неверный формат e-mail'), findsOneWidget);
    expect(find.text('Минимум 6 символов'), findsOneWidget);
  });

  testWidgets('режим регистрации добавляет обязательное поле «Имя»', (
    tester,
  ) async {
    await openLogin(tester);
    expect(field('Имя'), findsNothing);

    await tester.tap(find.text('Нет аккаунта? Зарегистрируйтесь'));
    await tester.pumpAndSettle();
    expect(field('Имя'), findsOneWidget);

    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pump();
    expect(find.text('Введите имя'), findsOneWidget);
  });

  testWidgets('успешный вход: token сохранён, сессия, переход в библиотеку', (
    tester,
  ) async {
    final app = await openLogin(tester);
    await tester.enterText(field('E-mail'), 'vitalii@booknest.md');
    await tester.enterText(field('Пароль'), 'parola123');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Моя библиотека'), findsOneWidget);
    expect(app.router.state.uri.path, '/books');
    expect(app.session.name, 'Vitalii');
    expect(await TokenStore().read(), 'jwt-abc');
    expect(app.library.fetches, isNotEmpty); // данные вошедшего уже грузятся
  });

  testWidgets('неверный пароль: текст сервера в SnackBar, остаёмся на входе', (
    tester,
  ) async {
    final app = await openLogin(tester);
    await tester.enterText(field('E-mail'), 'vitalii@booknest.md');
    await tester.enterText(field('Пароль'), 'wrong-pass');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Неверный email или пароль'), findsOneWidget);
    expect(app.router.state.uri.path, '/login');
    expect(app.session.isSignedIn, isFalse);
  });
}
