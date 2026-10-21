import 'package:go_router/go_router.dart';

import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/community_screen.dart';
import 'screens/library_screen.dart';
import 'screens/loan_request_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_shell.dart';

/// Router строится в main(): стартовый адрес решает сохранённый token
/// (вошёл — сразу в библиотеку, нет — на вход), а token читается асинхронно.
/// Поэтому late: без него «final router = …» потребовал бы значения сразу.
/// Глобальный объект, строится один раз: после изменений карты нужен restart (R).
late final GoRouter router;

/// Карта приложения: каждый экран ТЗ получает адрес, как маленький REST API.
final appRoutes = <RouteBase>[
  // ВНЕ shell-а: у входа нет вкладок.
  GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
  StatefulShellRoute.indexedStack(
    builder: (_, _, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: [
      // Каждая ветка — вкладка со своим стеком: детали и формы — её под-маршруты.
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/books',
            builder: (_, _) => const LibraryScreen(),
            routes: [
              // Пути под-маршрутов относительные. 'new' — ФИКСИРОВАННЫЙ сегмент,
              // строго перед ':id', иначе int.parse('new') упадёт.
              GoRoute(path: 'new', builder: (_, _) => const BookFormScreen()),
              GoRoute(
                path: ':id', // /books/7 — параметр пути всегда String
                builder: (_, state) => BookDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'edit', // /books/7/edit
                    builder: (_, state) => BookFormScreen(
                      bookId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/community',
            builder: (_, _) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => BookDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'request', // /community/9/request
                    builder: (_, state) => LoanRequestScreen(
                      bookId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/loans', builder: (_, _) => const LoansScreen()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),
    ],
  ),
];
