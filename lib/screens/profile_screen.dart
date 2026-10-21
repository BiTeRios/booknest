import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth_api.dart';
import '../data/loan.dart';
import '../models/book_list_model.dart';
import '../models/loans_model.dart';
import '../models/session_model.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_view.dart';

/// Профиль пользователя: данные, статистика обменов, настройки, выход.
/// Переключатель аварии L4 удалён вместе с mock-ом: ошибку теперь честно
/// провоцирует остановка сервера.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Выход — блокирующее решение, поэтому диалог с await, а не SnackBar.
  Future<void> _logout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Выйти из аккаунта?',
      message: 'Чтобы снова увидеть свою библиотеку, нужно будет войти.',
      confirmLabel: 'Да, выйти',
    );
    // После await context используется только под context.mounted.
    if (!ok || !context.mounted) return;
    await context.read<AuthApi>().logout(); // token выбрасывается из prefs
    if (!context.mounted) return;
    context.read<SessionModel>().signOut(); // read: действие в callback-е
    context.go('/login'); // go: раздел с вкладками уходит из стека
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // watch — в build: при входе/выходе профиль перерисуется сам.
    final session = context.watch<SessionModel>();
    final title = session.name ?? session.email ?? 'Гость';
    final initials = title
        .split(RegExp(r'[\s.@]+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                initials,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            session.email ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const _Stats(),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Напоминать о сроке возврата'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.history),
                  title: Text('История обменов'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('О приложении'),
                  subtitle: Text('BookNest 1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}

/// Статистика из моделей — тоже данные из хранилища, поэтому тоже три состояния.
class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryModel>();
    final loans = context.watch<LoansModel>();

    if (library.isLoading || loans.isLoading) {
      return const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if ((library.error ?? loans.error) case final error?) {
      return ErrorView(
        message: error,
        onRetry: () {
          context.read<LibraryModel>().load();
          context.read<LoansModel>().load();
        },
      );
    }
    final lentNow = loans.lent
        .where((l) => l.status == LoanStatus.active)
        .length;
    final borrowedNow = loans.borrowed
        .where((l) => l.status == LoanStatus.active)
        .length;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            // со страницами сервера: «10+» — загружено 10, есть ещё
            value: '${library.books.length}${library.hasMore ? '+' : ''}',
            label: 'книг',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(value: '$lentNow', label: 'выдано'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(value: '$borrowedNow', label: 'взято'),
        ),
      ],
    );
  }
}

/// Плитка статистики: крупное число и подпись.
class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.headlineSmall),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
