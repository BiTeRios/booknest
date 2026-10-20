import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/loan.dart';
import 'book_cover.dart';
import 'status_chip.dart';

/// Карточка обмена на экране «Мои обмены».
class LoanTile extends StatelessWidget {
  final Loan loan;

  /// true — я выдал книгу (показываем заёмщика), false — я её взял (показываем владельца).
  final bool lent;

  /// Действие внизу карточки, например «Отметить возврат».
  final Widget? action;

  const LoanTile({
    super.key,
    required this.loan,
    required this.lent,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(title: loan.bookTitle, width: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.bookTitle,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        loan.bookAuthor,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lent
                            ? 'Заёмщик: ${loan.borrowerName}'
                            : 'Владелец: ${loan.ownerName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip.loan(loan),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${formatDate(loan.startDate)} — ${formatDate(loan.dueDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
                Text(
                  _deadlineLabel(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: loan.isOverdue ? theme.colorScheme.error : muted,
                  ),
                ),
              ],
            ),
            if (action != null)
              Align(alignment: Alignment.centerRight, child: action),
          ],
        ),
      ),
    );
  }

  /// «осталось 9 дн.», «просрочено на 1 дн.» или «возвращена».
  String _deadlineLabel() {
    if (loan.status == LoanStatus.returned) return 'возвращена';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = loan.dueDate.difference(today).inDays;
    if (days < 0) return 'просрочено на ${-days} дн.';
    if (days == 0) return 'вернуть сегодня';
    return 'осталось $days дн.';
  }
}
