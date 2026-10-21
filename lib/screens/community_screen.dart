import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/book.dart';
import '../models/book_list_model.dart';
import '../widgets/book_card.dart';
import '../widgets/error_view.dart';
import '../widgets/genre_filter_bar.dart';
import '../widgets/load_more_tail.dart';

/// «Книги сообщества»: что есть у других, с кнопкой «Запросить».
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CommunityModel>();

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!,
        onRetry: () => context.read<CommunityModel>().load(),
      );
    } else if (model.visibleBooks.isEmpty) {
      body = const Center(child: Text('Ничего не найдено'));
    } else {
      final books = model.visibleBooks;
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        // +1 — хвост, который догружает следующую страницу
        itemCount: books.length + (model.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == books.length) {
            return LoadMoreTail(
              error: model.loadMoreError,
              onLoadMore: model.loadMore,
              onRetry: model.retryLoadMore,
            );
          }
          final book = books[index];
          return BookCard(
            key: ValueKey(book.id),
            book: book,
            showOwner: true,
            onTap: () => context.push('/community/${book.id}'),
            // выданную книгу сейчас запросить нельзя — кнопки нет
            trailing: book.status == BookStatus.available
                ? FilledButton.tonal(
                    onPressed: () =>
                        context.push('/community/${book.id}/request'),
                    child: const Text('Запросить'),
                  )
                : null,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги сообщества'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CommunityModel>().load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Найти книгу у сокурсников',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              // тап мимо поля убирает фокус — клавиатура не «возвращается» после диалогов
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              // Поиск идёт на сервере: запрос — по Enter, очистка — сразу.
              textInputAction: TextInputAction.search,
              onSubmitted: (q) => context.read<CommunityModel>().search(q),
              onChanged: (q) {
                if (q.isEmpty) context.read<CommunityModel>().search('');
              },
            ),
          ),
          GenreFilterBar(
            genres: bookGenres,
            selected: model.genre,
            onSelected: (g) => context.read<CommunityModel>().setGenre(g),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
