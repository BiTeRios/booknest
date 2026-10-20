import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/book_card.dart';
import '../widgets/genre_filter_bar.dart';

/// «Книги сообщества»: что есть у других, с кнопкой «Запросить».
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Книги сообщества')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Найти книгу у сокурсников',
              leading: Icon(Icons.search),
              elevation: WidgetStatePropertyAll(0),
            ),
          ),
          const GenreFilterBar(genres: bookGenres),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mockCommunityBooks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final book = mockCommunityBooks[index];
                return BookCard(
                  book: book,
                  showOwner: true,
                  // выданную книгу сейчас запросить нельзя — кнопки нет
                  trailing: book.status == BookStatus.available
                      ? FilledButton.tonal(
                          onPressed: () {},
                          child: const Text('Запросить'),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
