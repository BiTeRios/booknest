import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/book_card.dart';
import '../widgets/genre_filter_bar.dart';

/// «Моя библиотека»: список своих книг с поиском и фильтром по жанру.
/// Поиск и фильтр на L2 только визуальные — работать начнут на L4.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Моя библиотека')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Поиск по названию или автору',
              leading: Icon(Icons.search),
              elevation: WidgetStatePropertyAll(0),
            ),
          ),
          const GenreFilterBar(genres: bookGenres),
          Expanded(
            child: ListView.separated(
              // снизу место под FAB, чтобы он не закрывал последнюю карточку
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: mockMyBooks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final book = mockMyBooks[index];
                return BookCard(
                  book: book,
                  // push: «зайду и вернусь» — карточка ложится поверх списка
                  onTap: () => context.push('/books/${book.id}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/books/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить книгу'),
      ),
    );
  }
}
