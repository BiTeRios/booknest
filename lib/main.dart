import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';

void main() => runApp(const BookNestApp());

/// Корень приложения: MaterialApp и визуальная тема Material 3.
class BookNestApp extends StatelessWidget {
  const BookNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp.router: навигацию принимает go_router, параметра home: больше нет —
    // стартовый экран задаёт initialLocation в router.dart.
    return MaterialApp.router(
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
      // Стандартные тексты Material (календарь, подсказки кнопок) — по-русски.
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
