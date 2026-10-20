import 'package:flutter/material.dart';

import '../data/mock_data.dart';

/// Смысловой тон бейджа; конкретные цвета выбирает тема.
enum StatusTone { positive, warning, negative, neutral }

/// Бейдж статуса книги или обмена.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;

  const StatusChip({super.key, required this.label, required this.tone});

  /// Статус книги: доступна / выдана.
  factory StatusChip.book(BookStatus status, {Key? key}) => StatusChip(
    key: key,
    label: status.label,
    tone: status == BookStatus.available
        ? StatusTone.positive
        : StatusTone.warning,
  );

  /// Статус обмена: активен / просрочен / возвращён.
  factory StatusChip.loan(Loan loan, {Key? key}) {
    if (loan.isOverdue) {
      return StatusChip(
        key: key,
        label: 'Просрочен',
        tone: StatusTone.negative,
      );
    }
    return StatusChip(
      key: key,
      label: loan.status.label,
      tone: loan.status == LoanStatus.active
          ? StatusTone.positive
          : StatusTone.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      StatusTone.positive => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      StatusTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      StatusTone.negative => (scheme.errorContainer, scheme.onErrorContainer),
      StatusTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}
