import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() => runApp(const BookNestApp());

/// Корень приложения: MaterialApp и визуальная тема Material 3.
class BookNestApp extends StatelessWidget {
  const BookNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Вся палитра выводится из одного seed-цвета: тёмно-зелёный,
        // как переплёты старых книг и лампы читальных залов.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F5D50)),
        // Базовая типографика: точечная подстройка, остальное по умолчанию.
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // Приложение стартует со входа; на L3 вместо home: придёт go_router.
      home: const LoginScreen(),
    );
  }
}
