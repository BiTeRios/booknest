import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:booknest/data/book.dart';
import 'package:booknest/data/book_repository.dart';
import 'package:booknest/data/result.dart';
import 'package:booknest/models/book_list_model.dart';

import '../support/fakes.dart';

/// Подписчик-«экран»: записывает, что модель показывала при каждом извещении.
List<String> recordStates(BookListModel model) {
  final log = <String>[];
  model.addListener(
    () => log.add(
      model.isLoading
          ? 'loading'
          : model.error != null
          ? 'error'
          : 'data(${model.books.length})',
    ),
  );
  return log;
}

void main() {
  const pageSize = BookListModel.pageSize;
  late FakeBookRepository repo;
  late LibraryModel model;

  setUp(() {
    repo = FakeBookRepository([for (var i = 1; i <= 25; i++) book(i)]);
    model = LibraryModel(repo);
  });

  group('триада загрузки', () {
    test('load: «грузится» → данные, каждое состояние извещает', () async {
      final states = recordStates(model);
      repo.gate = Completer();

      final loading = model.load();
      expect(model.isLoading, isTrue); // экран уже рисует spinner
      repo.gate!.complete();
      await loading;

      expect(states, ['loading', 'data($pageSize)']);
      expect(model.error, isNull);
      expect(repo.fetches.single.scope, BookScope.mine);
    });

    test('ошибка: «грузится» → ошибка; retry возвращает данные', () async {
      final states = recordStates(model);
      repo.listError = networkDown;
      await model.load();
      expect(model.error, 'Нет сети — повторите попытку');
      expect(model.books, isEmpty);

      repo.listError = null; // сеть вернулась — пользователь жмёт «Повторить»
      await model.load();
      expect(model.error, isNull);
      expect(states, ['loading', 'error', 'loading', 'data($pageSize)']);
    });

    test('CommunityModel просит книги сообщества', () async {
      await CommunityModel(repo).load();
      expect(repo.fetches.single.scope, BookScope.community);
    });

    test('список наружу только для чтения', () async {
      await model.load();
      expect(() => model.books.add(book(99)), throwsUnsupportedError);
    });
  });

  group('пагинация', () {
    test('страницы приклеиваются, пока сервер отдаёт полные', () async {
      await model.load();
      expect(model.hasMore, isTrue);

      await model.loadMore();
      expect(model.books.length, 2 * pageSize);
      expect(model.hasMore, isTrue);

      await model.loadMore(); // 25 книг: третья страница неполная
      expect(model.books.length, 25);
      expect(model.hasMore, isFalse);

      await model.loadMore(); // больше нечего — запроса нет
      expect([for (final f in repo.fetches) f.page], [1, 2, 3]);
    });

    test('guard: два вызова из build подряд — одна страница', () async {
      await model.load();
      repo.gate = Completer();
      final first = model.loadMore();
      final second = model.loadMore(); // пока первый в полёте
      repo.gate!.complete();
      await Future.wait([first, second]);

      expect([for (final f in repo.fetches) f.page], [1, 2]);
      expect(model.books.length, 2 * pageSize); // без дублей
    });

    test(
      'сбой догрузки: список цел, хвост с ошибкой, retry продолжает',
      () async {
        await model.load();
        repo.listError = networkDown;
        await model.loadMore();
        expect(model.books.length, pageSize); // уже загруженное не пропало
        expect(model.loadMoreError, 'Нет сети — повторите попытку');

        await model.loadMore(); // ошибка в хвосте — новых запросов нет
        expect(repo.fetches.length, 2);

        repo.listError = null;
        model.retryLoadMore();
        await model.loadMore();
        expect(model.loadMoreError, isNull);
        expect(model.books.length, 2 * pageSize);
      },
    );
  });

  group('поиск и жанр — на сервере', () {
    test('search обрезает пробелы и начинает с первой страницы', () async {
      await model.load();
      await model.loadMore();
      await model.search('  Книга 1  ');

      final last = repo.fetches.last;
      expect(last.page, 1);
      expect(last.search, 'Книга 1');
      expect(model.query, 'Книга 1');
    });

    test('setGenre передаёт жанр, null — «Все»', () async {
      repo.books.add(book(50, genre: 'IT'));
      await model.setGenre('IT');
      expect(repo.fetches.last.genre, 'IT');
      expect([for (final b in model.books) b.id], [50]);

      await model.setGenre(null);
      expect(repo.fetches.last.genre, isNull);
    });
  });

  group('мутации: вердикт хранилища → изменение → извещение', () {
    setUp(() async => model.load());

    test('add: книга с id от хранилища — первой в списке', () async {
      var notified = 0;
      model.addListener(() => notified++);
      final error = await model.add(
        const Book.draft(title: 'Дюна', author: 'Герберт', genre: 'Фантастика'),
      );
      expect(error, isNull);
      expect(model.books.first.title, 'Дюна');
      expect(model.books.first.id, isNot(0));
      expect(notified, 1);
    });

    test('update заменяет книгу на месте', () async {
      final edited = model.books[2].copyWith(title: 'Новое название');
      expect(await model.update(edited), isNull);
      expect(model.books[2].title, 'Новое название');
      expect(model.books.length, pageSize);
    });

    test('remove убирает книгу', () async {
      expect(await model.remove(1), isNull);
      expect(model.byId(1), isNull);
      expect(model.books.length, pageSize - 1);
    });

    test(
      'отказ хранилища: состояние нетронуто, без извещений, сообщение наружу',
      () async {
        var notified = 0;
        model.addListener(() => notified++);
        repo.writeError = const Err('Запись не существует');

        expect(await model.remove(1), 'Запись не существует');
        expect(
          await model.add(
            const Book.draft(title: 'x', author: 'yy', genre: 'IT'),
          ),
          'Запись не существует',
        );
        expect(model.books.length, pageSize);
        expect(model.byId(1), isNotNull);
        expect(notified, 0);
      },
    );

    test('markStatus: обмен сменил статус — модель синхронна без запроса', () {
      model.markStatus(3, BookStatus.lent);
      expect(model.byId(3)!.status, BookStatus.lent);
      expect(repo.fetches.length, 1);
    });
  });
}
