import 'package:flutter/material.dart';

/// Обложка книги. На L2 — цветная плашка с инициалами названия
/// (цвета берутся из ColorScheme); на L5 сюда придёт изображение с сервера.
class BookCover extends StatelessWidget {
  final String title;
  final double width;

  const BookCover({super.key, required this.title, this.width = 48});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Три тональные пары темы чередуются по названию: у соседних книг разный цвет,
    // а у одной и той же книги — всегда один и тот же.
    final (
      background,
      foreground,
    ) = switch (title.runes.fold(0, (a, b) => a + b) % 3) {
      0 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      1 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Container(
      width: width,
      height: width * 1.5, // пропорции книжной обложки 2:3
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(width / 8),
      ),
      child: Text(
        _initials(title),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          fontSize: width / 3,
        ),
      ),
    );
  }

  /// «Мастер и Маргарита» → «МИ», «Дюна» → «Д».
  static String _initials(String title) {
    final words = title
        .split(RegExp(r'[\s.,«»…]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}
