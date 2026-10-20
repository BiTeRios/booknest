import 'package:flutter/material.dart';

/// Горизонтальный ряд фильтров по жанру: «Все» + жанры.
/// На L2 фильтры только визуальные — работать они начнут на L4.
class GenreFilterBar extends StatelessWidget {
  final List<String> genres;

  /// Выбранный жанр; null — «Все».
  final String? selected;

  final ValueChanged<String?>? onSelected;

  const GenreFilterBar({
    super.key,
    required this.genres,
    this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = index == 0 ? null : genres[index - 1];
          return Center(
            child: FilterChip(
              label: Text(genre ?? 'Все'),
              selected: genre == selected,
              onSelected: (_) => onSelected?.call(genre),
            ),
          );
        },
      ),
    );
  }
}
