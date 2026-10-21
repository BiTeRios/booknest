import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:booknest/data/book.dart';
import 'package:booknest/data/book_repository.dart';
import 'package:booknest/data/cached_book_repository.dart';
import 'package:booknest/data/cached_loan_repository.dart';
import 'package:booknest/data/loan.dart';
import 'package:booknest/data/loan_repository.dart';
import 'package:booknest/data/offline_cache.dart';
import 'package:booknest/data/result.dart';

import '../support/fakes.dart';

List<int> ids(Result<List<Book>> r) => [
  for (final b in (r as Ok<List<Book>>).value) b.id,
];

void main() {
  // shared_preferences в памяти: setMockInitialValues — чистый «диск» на тест.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('OfflineCache', () {
    final cache = OfflineCache();

    test('putList → getList: те же записи и момент сохранения', () async {
      final before = DateTime.now();
      await cache.putList('books:mine:1:10::', [
        for (final b in [book(1), book(2)]) b.toStorageJson(),
      ]);
      final cached = await cache.getList('books:mine:1:10::', Book.fromJson);

      expect([for (final b in cached!.items) b.title], ['Книга 1', 'Книга 2']);
      expect(cached.savedAt.isBefore(before), isFalse);
    });

    test('нет записи → null', () async {
      expect(await cache.getList('books:mine:9:10::', Book.fromJson), isNull);
    });

    test('битая запись (не JSON / не та форма) → null, а не падение', () async {
      SharedPreferences.setMockInitialValues({
        'cache:a': '{oops',
        'cache:b': '{"savedAt": "2026-10-21T10:00:00", "items": [{"id": "x"}]}',
      });
      expect(await cache.getList('a', Book.fromJson), isNull);
      expect(await cache.getList('b', Book.fromJson), isNull);
    });

    test(
      'clear стирает только кэш — чужие ключи (тема и т. п.) целы',
      () async {
        SharedPreferences.setMockInitialValues({
          'cache:books:mine:1:10::': '{}',
          'cache:loans:lent': '{}',
          'auth_token': 'jwt',
        });
        await cache.clear();
        final keys = (await SharedPreferences.getInstance()).getKeys();
        expect(keys, {'auth_token'});
      },
    );
  });

  group('CachedBookRepository — декоратор над «сервером»', () {
    late FakeBookRepository remote;
    late CachedBookRepository repo;
    late List<DateTime?> sources; // что узнал бы баннер

    setUp(() {
      remote = FakeBookRepository([book(1), book(2), book(3)]);
      sources = [];
      repo = CachedBookRepository(
        remote,
        OfflineCache(),
        onSource: sources.add,
      );
    });

    test(
      'сервер ответил — данные с сервера, источник «онлайн» (null)',
      () async {
        expect(ids(await repo.fetchAll(limit: 10)), [1, 2, 3]);
        expect(sources, [null]);
      },
    );

    test('сети нет — последний снимок того же запроса и его время', () async {
      await repo.fetchAll(limit: 10); // онлайн: снимок сохранён
      remote.books.clear(); // на «сервере» поменялось — но до него не дойти
      remote.listError = networkDown;

      final offline = await repo.fetchAll(limit: 10);
      expect(ids(offline), [1, 2, 3]);
      expect(sources.length, 2);
      expect(sources.last, isNotNull); // баннер «данные от …»
    });

    test('сети нет и снимка нет — честная ошибка', () async {
      remote.listError = networkDown;
      final result = await repo.fetchAll(limit: 10);
      expect((result as Err).isNetwork, isTrue);
      expect(sources, isEmpty);
    });

    test(
      'снимок у каждого запроса свой: другая страница/поиск/scope — не он',
      () async {
        await repo.fetchAll(limit: 10);
        remote.listError = networkDown;
        for (final other in [
          repo.fetchAll(limit: 10, page: 2),
          repo.fetchAll(limit: 10, search: 'Книга 1'),
          repo.fetchAll(limit: 10, genre: 'IT'),
          repo.fetchAll(limit: 10, scope: BookScope.community),
        ]) {
          expect(await other, isA<Err>());
        }
      },
    );

    test('ошибку СЕРВЕРА (400/404) кэш не подменяет', () async {
      await repo.fetchAll(limit: 10);
      remote.listError = const Err('Ошибка сервера (INTERNAL)');
      final result = await repo.fetchAll(limit: 10);
      expect((result as Err).msg, 'Ошибка сервера (INTERNAL)');
    });

    test('изменения идут мимо кэша прямо на сервер', () async {
      final created = await repo.create(
        const Book.draft(title: 'Дюна', author: 'Герберт', genre: 'Фантастика'),
      );
      expect((created as Ok<Book>).value.id, 100);
      expect(remote.books.first.title, 'Дюна');
      expect(await repo.delete(1), isA<Ok<void>>());
      expect(await repo.fetchById(1), isA<Err>());
      expect(await repo.update(book(2)), isA<Ok<Book>>());
    });
  });

  group('CachedLoanRepository', () {
    test('роли кэшируются отдельно; без сети — снимок своей роли', () async {
      final remote = FakeLoanRepository(
        lent: [loan(1)],
        borrowed: [loan(2), loan(3)],
      );
      final sources = <DateTime?>[];
      final repo = CachedLoanRepository(
        remote,
        OfflineCache(),
        onSource: sources.add,
      );

      await repo.fetchAll(role: LoanRole.lent);
      await repo.fetchAll(role: LoanRole.borrowed);
      remote.listErrors[LoanRole.lent] = networkDown;
      remote.listErrors[LoanRole.borrowed] = networkDown;

      final lent = await repo.fetchAll(role: LoanRole.lent) as Ok<List<Loan>>;
      final borrowed =
          await repo.fetchAll(role: LoanRole.borrowed) as Ok<List<Loan>>;
      expect([for (final l in lent.value) l.id], [1]);
      expect([for (final l in borrowed.value) l.id], [2, 3]);
      expect(
        borrowed.value.first.dueDate,
        loan(2).dueDate,
      ); // даты пережили JSON
      expect(sources.whereType<DateTime>().length, 2);
    });
  });
}
