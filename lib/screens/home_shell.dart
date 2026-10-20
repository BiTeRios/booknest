import 'package:flutter/material.dart';

import 'community_screen.dart';
import 'library_screen.dart';
import 'loans_screen.dart';
import 'profile_screen.dart';

/// Временная обёртка L2 с NavigationBar — только чтобы на защите можно было
/// дойти до каждого экрана. На L3 её заменит StatefulShellRoute из go_router.
///
/// Единственное допустимое исключение из правила «StatelessWidget повсюду»:
/// состояние здесь — только индекс выбранной вкладки, содержимое экранов статично.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    LibraryScreen(),
    CommunityScreen(),
    LoansScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
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
