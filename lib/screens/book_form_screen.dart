import 'package:flutter/material.dart';

import '../data/mock_data.dart';

/// Форма новой книги: название, автор, жанр, обложка.
/// На L2 — макет без валидации и без сохранения (валидация — L3).
class BookFormScreen extends StatelessWidget {
  const BookFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Новая книга')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 144,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Загрузить обложку'),
            ),
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Название *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Автор *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            label: const Text('Жанр'),
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              for (final genre in bookGenres)
                DropdownMenuEntry(value: genre, label: genre),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '* — обязательные поля',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_outlined),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
