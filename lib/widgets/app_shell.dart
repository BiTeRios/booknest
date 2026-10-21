import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/loans_model.dart';
import 'offline_banner.dart';

/// Обёртка с постоянными вкладками: NavigationBar остаётся на экране,
/// пока меняется содержимое. StatelessWidget — текущую вкладку знает router.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // содержимое текущей вкладки со своим стеком
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OfflineBanner(), // L6: видна, только когда данные из кэша
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            // Повторное нажатие на активную вкладку возвращает её к корню
            // (например, из карточки книги обратно к списку).
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: 'Библиотека',
              ),
              const NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Сообщество',
              ),
              NavigationDestination(
                // Один живой угол — Consumer: перестраивается только бейдж,
                // а не вся панель, когда меняется число активных обменов.
                icon: Consumer<LoansModel>(
                  builder: (context, loans, child) => Badge(
                    isLabelVisible: loans.activeCount > 0,
                    label: Text('${loans.activeCount}'),
                    child: child!,
                  ),
                  child: const Icon(Icons.swap_horiz),
                ),
                label: 'Обмены',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Профиль',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
