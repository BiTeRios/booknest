import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../data/mock_data.dart';
import '../widgets/book_cover.dart';
import '../widgets/info_row.dart';
import '../widgets/status_chip.dart';

/// Карточка книги: автор, жанр, обложка, статус (доступна / выдана).
/// Для своей книги — кнопки редактирования, для чужой — «Запросить книгу».
class BookDetailScreen extends StatelessWidget {
  /// Идентичность книги приходит из адреса (/books/7) — сам объект экран ищет сам.
  final int id;

  const BookDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // Сегодня поиск идёт в mock-данных, на L4 — через Repository, на L5 — в backend-е:
    // адрес остаётся, источник данных меняется под низом.
    final book = [
      ...mockMyBooks,
      ...mockCommunityBooks,
    ].where((b) => b.id == id).firstOrNull;
    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Книга не найдена')),
      );
    }

    final theme = Theme.of(context);
    final isMine = book.ownerId == currentUser.id;
    // Если книга выдана — показываем, у кого она и до какого срока.
    final activeLoan = [...mockLentLoans, ...mockBorrowedLoans]
        .where((l) => l.bookId == book.id && l.status == LoanStatus.active)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка книги'),
        actions: [
          if (isMine)
            IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {},
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: BookCover(title: book.title, width: 120)),
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
                      value: activeLoan.borrowerId == currentUser.id
                          ? 'Вас'
                          : activeLoan.borrowerName,
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
