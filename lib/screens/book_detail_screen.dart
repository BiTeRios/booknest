import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/book.dart';
import '../data/format.dart';
import '../models/book_list_model.dart';
import '../models/loans_model.dart';
import '../widgets/book_cover.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/info_row.dart';
import '../widgets/status_chip.dart';

/// Карточка книги: автор, жанр, обложка, статус (доступна / выдана).
/// Для своей книги — кнопки редактирования, для чужой — «Запросить книгу».
class BookDetailScreen extends StatelessWidget {
  /// Идентичность книги приходит из адреса (/books/7) — сам объект экран ищет сам.
  final int id;

  const BookDetailScreen({super.key, required this.id});

  /// Деструктивное действие: подтверждение → удаление через модель → назад.
  Future<void> _delete(BuildContext context, Book book) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Удалить книгу?',
      message: '«${book.title}» исчезнет из вашей библиотеки.',
      confirmLabel: 'Удалить',
    );
    if (!ok || !context.mounted) return;
    final error = await context.read<LibraryModel>().remove(book.id);
    if (!context.mounted) return; // экран может умереть, пока «запрос» летит
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Книга «${book.title}» удалена')));
    context.pop(); // объекта больше нет — его экран уходит из стека
  }

  @override
  Widget build(BuildContext context) {
    // Адрес остался прежним (L3), источник поменялся под низом: теперь книгу
    // ищем через модели, а модели — через Repository.
    final library = context.watch<LibraryModel>();
    final community = context.watch<CommunityModel>();
    final loans = context.watch<LoansModel>();

    final mine = library.byId(id);
    final book = mine ?? community.byId(id);
    if (book == null) {
      // У null два смысла: список ещё грузится или такого id нет.
      final Widget body;
      if (library.isLoading || community.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if ((library.error ?? community.error) case final error?) {
        body = ErrorView(
          message: error,
          onRetry: () {
            context.read<LibraryModel>().load();
            context.read<CommunityModel>().load();
          },
        );
      } else {
        body = const Center(child: Text('Книга не существует'));
      }
      return Scaffold(appBar: AppBar(), body: body);
    }

    final theme = Theme.of(context);
    final isMine = mine != null;
    // Если книга выдана — показываем, у кого она и до какого срока.
    final activeLoan = loans.activeLoanFor(book.id);
    final borrowedByMe =
        activeLoan != null && loans.borrowed.any((l) => l.id == activeLoan.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка книги'),
        actions: [
          if (isMine)
            IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, book),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: BookCover(
              title: book.title,
              coverUrl: book.coverUrl,
              width: 120,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            book.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(child: StatusChip.book(book.status)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.person_outline,
                    label: 'Автор',
                    value: book.author,
                  ),
                  InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Жанр',
                    value: book.genre,
                  ),
                  InfoRow(
                    icon: Icons.home_outlined,
                    label: 'Владелец',
                    value: isMine ? 'Вы' : book.ownerName,
                  ),
                  InfoRow(
                    icon: Icons.info_outline,
                    label: 'Статус',
                    value: book.status.label,
                  ),
                  if (activeLoan != null) ...[
                    InfoRow(
                      icon: Icons.handshake_outlined,
                      label: 'Сейчас у',
                      value: borrowedByMe ? 'Вас' : activeLoan.borrowerName,
                    ),
                    InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Вернуть до',
                      value: formatDate(activeLoan.dueDate),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isMine)
            OutlinedButton.icon(
              onPressed: () => context.push('/books/${book.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Редактировать'),
            )
          else
            FilledButton.icon(
              onPressed: book.status == BookStatus.available
                  ? () => context.push('/community/${book.id}/request')
                  : null,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(
                book.status == BookStatus.available
                    ? 'Запросить книгу'
                    : 'Книга сейчас выдана',
              ),
            ),
        ],
      ),
    );
  }
}
