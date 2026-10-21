import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/api_config.dart';
import 'data/auth_api.dart';
import 'data/http_book_repository.dart';
import 'data/http_loan_repository.dart';
import 'data/token_store.dart';
import 'models/book_list_model.dart';
import 'models/loans_model.dart';
import 'models/session_model.dart';
import 'router.dart';

/// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prefs нужны до runApp
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null; // запуск решает по token-у
  final user = loggedIn ? await tokens.readUser() : null;

  router = GoRouter(
    initialLocation: loggedIn ? '/books' : '/login',
    routes: appRoutes, // карта L3 — без изменений
  );

  // Источник данных — backend. 401 в любом запросе: token уже стёрт,
  // корень уводит на вход (в одном месте; хранилища не знают о router-е).
  final api = ApiClient(
    apiBase,
    tokens,
    onUnauthorized: () => router.go('/login'),
  );
  final books = HttpBookRepository(api);
  final loans = HttpLoanRepository(api);

  runApp(
    // Модели монтируются НАД router-ом, чтобы их видели все экраны.
    MultiProvider(
      providers: [
        // Вход и регистрация на сервере; token — в shared_preferences.
        Provider<AuthApi>(create: (_) => AuthApi(apiBase, tokens)),
        // Модели — фабрикой: Provider создаёт их лениво и сам вызовет dispose.
        // DI: хранилище — в конструктор; каскад ..load() — первая загрузка.
        // Сессия после перезапуска восстанавливается из prefs.
        ChangeNotifierProvider(
          create: (_) {
            final session = SessionModel();
            if (user != null) {
              session.signIn(email: user.email, name: user.name);
            }
            return session;
          },
        ),
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
