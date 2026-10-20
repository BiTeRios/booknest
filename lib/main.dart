import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/mock_book_repository.dart';
import 'data/mock_loan_repository.dart';
import 'models/book_list_model.dart';
import 'models/loans_model.dart';
import 'models/session_model.dart';
import 'router.dart';

/// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
void main() {
  final books = MockBookRepository(); // на L5: HTTP-вариант — и всё
  final loans = MockLoanRepository(books);

  runApp(
    // Модели монтируются НАД router-ом, чтобы их видели все экраны.
    MultiProvider(
      providers: [
        // Леса демонстрации аварии (переключатель в профиле) — исчезнут на L5.
        // Repository не ChangeNotifier и живёт всё приложение — .value оправдан.
        Provider<MockBookRepository>.value(value: books),
        Provider<MockLoanRepository>.value(value: loans),
        // Модели — фабрикой: Provider создаёт их лениво и сам вызовет dispose.
        // DI: хранилище — в конструктор; каскад ..load() — первая загрузка.
        ChangeNotifierProvider(create: (_) => SessionModel()),
        ChangeNotifierProvider(create: (_) => LibraryModel(books)..load()),
        ChangeNotifierProvider(create: (_) => CommunityModel(books)..load()),
        ChangeNotifierProvider(create: (_) => LoansModel(loans)..load()),
      ],
      child: const BookNestApp(),
    ),
  );
}

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
