import 'package:flutter_test/flutter_test.dart';

import 'package:booknest/data/book.dart';
import 'package:booknest/data/loan.dart';

import '../support/fakes.dart';

// Граница JSON: язык сервера ⇄ доменная модель. Ошибка здесь не видна
// компилятору — её ловят только тесты.
void main() {
  group('Book.fromJson', () {
    test('полный ответ сервера', () {
      final b = Book.fromJson({
        'id': 7,
        'ownerId': 2,
        'ownerName': 'Ana Rusu',
        'title': 'Мастер и Маргарита',
        'author': 'Михаил Булгаков',
        'genre': 'Классика',
        'coverUrl': '/files/3',
        'status': 'lent',
      });
      expect(b.id, 7);
      expect(b.ownerId, 2);
      expect(b.ownerName, 'Ana Rusu');
      expect(b.title, 'Мастер и Маргарита');
      expect(b.coverUrl, '/files/3');
      expect(b.status, BookStatus.lent);
    });

    test(
      'необязательные поля: без ownerName/genre/coverUrl, статус по умолчанию',
      () {
        final b = Book.fromJson({
          'id': 1,
          'ownerId': 1,
          'title': 'Ion',
          'author': 'Liviu Rebreanu',
          'status': 'archived', // неизвестный статус не роняет приложение
        });
        expect(b.ownerName, '');
        expect(b.genre, '');
        expect(b.coverUrl, isNull);
        expect(b.status, BookStatus.available);
      },
    );

    test('тело не той формы бросает TypeError (хранилище превратит в Err)', () {
      expect(
        () => Book.fromJson({
          'id': '7',
          'ownerId': 1,
          'title': 'x',
          'author': 'y',
        }),
        throwsA(isA<TypeError>()),
      );
      expect(
        () =>
            Book.fromJson({'id': 7, 'ownerId': 1, 'author': 'y'}), // нет title
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('Book.toJson / toStorageJson', () {
    test('тело POST/PUT — без id, владельца и статуса: их решает сервер', () {
      final json = book(5, status: BookStatus.lent).toJson();
      expect(
        json.keys,
        unorderedEquals(['title', 'author', 'genre', 'coverUrl']),
      );
    });

    test('снимок для кэша переживает обратный разбор без потерь', () {
      final original = book(
        5,
        status: BookStatus.lent,
      ).copyWith(coverUrl: '/files/9');
      final restored = Book.fromJson(original.toStorageJson());
      expect(restored.toStorageJson(), original.toStorageJson());
    });
  });

  group('Loan', () {
    final serverJson = {
      'id': 3,
      'bookId': 7,
      'bookTitle': 'Дюна',
      'bookAuthor': 'Фрэнк Герберт',
      'ownerId': 1,
      'ownerName': 'Vitalii',
      'borrowerId': 2,
      'borrowerName': 'Ana Rusu',
      'startDate': '2026-10-01',
      'dueDate': '2026-11-05',
      'status': 'returned',
    };

    test('fromJson разбирает даты «YYYY-MM-DD» и статус', () {
      final l = Loan.fromJson(serverJson);
      expect(l.bookTitle, 'Дюна');
      expect(l.startDate, DateTime(2026, 10, 1));
      expect(l.dueDate, DateTime(2026, 11, 5));
      expect(l.status, LoanStatus.returned);
    });

    test('toJson: дата с ведущими нулями — так её ждёт сервер', () {
      final draft = Loan.request(bookId: 7, dueDate: DateTime(2026, 3, 9));
      expect(draft.toJson(), {
        'bookId': 7,
        'dueDate': '2026-03-09',
        'status': 'active',
      });
    });

    test('toStorageJson — тот же формат, что у сервера (обратный разбор)', () {
      expect(Loan.fromJson(serverJson).toStorageJson(), serverJson);
    });

    test(
      'isOverdue: вчера — просрочен, сегодня — ещё нет, возвращённый — никогда',
      () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        expect(loan(1, dueDate: yesterday).isOverdue, isTrue);
        expect(loan(1, dueDate: today).isOverdue, isFalse);
        expect(
          loan(1, dueDate: yesterday, status: LoanStatus.returned).isOverdue,
          isFalse,
        );
      },
    );
  });
}
