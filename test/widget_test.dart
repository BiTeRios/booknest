import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:booknest/data/auth_api.dart';
import 'package:booknest/data/token_store.dart';
import 'package:booknest/models/session_model.dart';
import 'package:booknest/screens/login_screen.dart';

void main() {
  testWidgets('Экран входа: пустой submit показывает ошибки валидации', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthApi>(
            create: (_) => AuthApi('http://localhost:0', TokenStore()),
          ),
          ChangeNotifierProvider(create: (_) => SessionModel()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('BookNest'), findsOneWidget);
    await tester.tap(find.text('Войти'));
    await tester.pump();
    // Невалидная форма на сервер не идёт — ошибки рисуются под полями.
    expect(find.text('Введите e-mail'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });
}
