import 'package:go_router/go_router.dart';

import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/community_screen.dart';
import 'screens/library_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

/// Карта приложения: каждый экран ТЗ получает адрес, как маленький REST API.
/// Глобальный объект, строится один раз: после изменений карты нужен restart (R).
final router = GoRouter(
  initialLocation: '/login', // приложение стартует со входа
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/books', builder: (_, _) => const LibraryScreen()),
    // ФИКСИРОВАННЫЙ сегмент — строго перед ':id', иначе «new» поймает
    // переменный сегмент и int.parse('new') упадёт.
    GoRoute(path: '/books/new', builder: (_, _) => const BookFormScreen()),
    GoRoute(
      path: '/books/:id', // /books/7 — параметр пути всегда String
      builder: (_, state) =>
          BookDetailScreen(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(path: '/community', builder: (_, _) => const CommunityScreen()),
    GoRoute(
      path: '/community/:id',
      builder: (_, state) =>
          BookDetailScreen(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(path: '/loans', builder: (_, _) => const LoansScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
  ],
);
