import 'package:flutter/material.dart';

import '../data/api_config.dart';

/// Обложка книги: изображение с сервера (L5, POST /files), а если его нет
/// или оно не загрузилось — цветная плашка с инициалами названия
/// (цвета берутся из ColorScheme).
class BookCover extends StatelessWidget {
  final String title;
  final double width;

  /// Относительный путь на сервере, например «/files/7»; null — обложки нет.
  final String? coverUrl;

  const BookCover({
    super.key,
    required this.title,
    this.width = 48,
    this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width / 8);
    final placeholder = _placeholder(context, radius);
    if (coverUrl == null) return placeholder;
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        '$apiBase$coverUrl',
        width: width,
        height: width * 1.5,
        fit: BoxFit.cover,
        // пока байты летят и если сервер недоступен — плашка с инициалами
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }

  Widget _placeholder(BuildContext context, BorderRadius radius) {
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
      decoration: BoxDecoration(color: background, borderRadius: radius),
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
