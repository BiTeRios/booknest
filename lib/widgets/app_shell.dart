import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Обёртка с постоянными вкладками: NavigationBar остаётся на экране,
/// пока меняется содержимое. StatelessWidget — текущую вкладку знает router.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // содержимое текущей вкладки со своим стеком
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // Повторное нажатие на активную вкладку возвращает её к корню
        // (например, из карточки книги обратно к списку).
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Библиотека',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Сообщество',
          ),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Обмены'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
