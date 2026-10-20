import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'book_cover.dart';
import 'status_chip.dart';

/// Карточка книги в списке: «Моя библиотека» и «Книги сообщества».
class BookCard extends StatelessWidget {
  final Book book;

  /// В списке сообщества показываем владельца книги.
  final bool showOwner;

  /// Дополнительный элемент справа, например кнопка «Запросить».
  final Widget? trailing;

  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.showOwner = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(title: book.title),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showOwner) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.ownerName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip.book(book.status),
                        Text(
                          book.genre,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
