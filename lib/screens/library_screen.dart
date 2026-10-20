import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/book.dart';
import '../models/book_list_model.dart';
import '../widgets/book_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/genre_filter_bar.dart';

/// «Моя библиотека»: свои книги с поиском и фильтром по жанру.
/// Данные — из LibraryModel; экран рисует три состояния: грузится / данные / ошибка.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryModel>(); // watch в build

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (model.error != null) {
      body = ErrorView(
        // 2) упало
        message: model.error!,
        onRetry: () => context.read<LibraryModel>().load(), // read: действие
      );
    } else {
      body = _BookList(books: model.visibleBooks); // 3) данные
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя библиотека'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LibraryModel>().load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Поиск по названию или автору',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              // тап мимо поля убирает фокус — клавиатура не «возвращается» после диалогов
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (q) => context.read<LibraryModel>().setQuery(q),
            ),
          ),
          GenreFilterBar(
            genres: bookGenres,
            selected: model.genre,
            onSelected: (g) => context.read<LibraryModel>().setGenre(g),
          ),
          Expanded(child: body),
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

class _BookList extends StatelessWidget {
  final List<Book> books;

  const _BookList({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('Ничего не найдено'));
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      // снизу место под FAB, чтобы он не закрывал последнюю карточку
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = books[index];
        return Dismissible(
          // идентичность из данных, а не UniqueKey: список удаляет и вставляет
          key: ValueKey(book.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
          ),
          // Удаляем здесь, а не в onDismissed: если хранилище откажет,
          // карточка вернётся на место, а не «повиснет» удалённой.
          confirmDismiss: (_) => _confirmAndRemove(context, book),
          child: BookCard(
            book: book,
            // push: «зайду и вернусь» — карточка ложится поверх списка
            onTap: () => context.push('/books/${book.id}'),
          ),
        );
      },
    );
  }

  Future<bool> _confirmAndRemove(BuildContext context, Book book) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Удалить книгу?',
      message: '«${book.title}» исчезнет из вашей библиотеки.',
      confirmLabel: 'Удалить',
    );
    if (!ok || !context.mounted) return false;
    final error = await context.read<LibraryModel>().remove(book.id);
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Книга «${book.title}» удалена')),
    );
    return error == null;
  }
}
