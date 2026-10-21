import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:booknest/data/api_client.dart';
import 'package:booknest/data/book.dart';
import 'package:booknest/data/book_repository.dart';
import 'package:booknest/data/http_book_repository.dart';
import 'package:booknest/data/http_loan_repository.dart';
import 'package:booknest/data/loan.dart';
import 'package:booknest/data/loan_repository.dart';
import 'package:booknest/data/result.dart';
import 'package:booknest/data/token_store.dart';

import '../support/fakes.dart';

/// JSON-ответ «сервера»; charset обязателен — иначе кириллица в latin1.
http.Response json(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> bookJson(int id) => book(id).toStorageJson();

// ApiClient и HTTP-хранилища без сети: вместо http.Client — MockClient,
// ответ которого решает тест. Проверяем все три слоя отказа.
void main() {
  late List<http.Request> requests;
  late int unauthorized;

  /// Клиент, у которого «сервер» — функция [handler].
  ApiClient api(Future<http.Response> Function(http.Request) handler) =>
      ApiClient(
        'http://api.test',
        TokenStore(),
        onUnauthorized: () => unauthorized++,
        client: MockClient((req) {
          requests.add(req);
          return handler(req);
        }),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'jwt-123'});
    requests = [];
    unauthorized = 0;
  });

  group('успешные ответы', () {
    test('GET /books: Bearer-токен, query и конверт {items, …}', () async {
      final repo = HttpBookRepository(
        api(
          (_) async => json({
            'items': [bookJson(1), bookJson(2)],
            'page': 2,
            'limit': 10,
            'total': 12,
          }, 200),
        ),
      );

      final result = await repo.fetchAll(
        scope: BookScope.community,
        page: 2,
        limit: 10,
        search: 'дюна',
        genre: 'Фантастика',
      );

      final req = requests.single;
      expect(req.method, 'GET');
      expect(req.url.path, '/books');
      expect(req.url.queryParameters, {
        'scope': 'community',
        'page': '2',
        'limit': '10',
        'search': 'дюна',
        'genre': 'Фантастика',
      });
      expect(req.headers['Authorization'], 'Bearer jwt-123');
      expect(result, isA<Ok<List<Book>>>());
      expect([for (final b in (result as Ok<List<Book>>).value) b.id], [1, 2]);
    });

    test('пустой поиск и жанр «Все» не попадают в query', () async {
      final repo = HttpBookRepository(
        api((_) async => json({'items': []}, 200)),
      );
      await repo.fetchAll(search: '');
      expect(
        requests.single.url.queryParameters.keys,
        unorderedEquals(['scope', 'page', 'limit']),
      );
    });

    test('POST /books → 201: тело из toJson, книга с id от сервера', () async {
      final repo = HttpBookRepository(
        api((_) async => json(bookJson(42), 201)),
      );
      final result = await repo.create(
        const Book.draft(
          title: 'Дюна',
          author: 'Фрэнк Герберт',
          genre: 'Фантастика',
        ),
      );

      final req = requests.single;
      expect(req.method, 'POST');
      expect(jsonDecode(req.body), {
        'title': 'Дюна',
        'author': 'Фрэнк Герберт',
        'genre': 'Фантастика',
        'coverUrl': null,
      });
      expect((result as Ok<Book>).value.id, 42);
    });

    test('DELETE → 204: пустое тело не разбирается', () async {
      final repo = HttpBookRepository(api((_) async => http.Response('', 204)));
      expect(await repo.delete(5), isA<Ok<void>>());
      expect(requests.single.url.path, '/books/5');
    });

    test('PUT /loans/{id}: возврат уходит как status=returned', () async {
      final returned = loan(3, status: LoanStatus.returned);
      final repo = HttpLoanRepository(
        api((_) async => json(returned.toStorageJson(), 200)),
      );
      final result = await repo.update(returned);
      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/loans/3');
      expect(jsonDecode(requests.single.body)['status'], 'returned');
      expect((result as Ok<Loan>).value.status, LoanStatus.returned);
    });

    test('GET /loans просит роль и весь список сразу', () async {
      final repo = HttpLoanRepository(
        api(
          (_) async => json({
            'items': [loan(1).toStorageJson()],
          }, 200),
        ),
      );
      await repo.fetchAll(role: LoanRole.borrowed);
      expect(requests.single.url.queryParameters, {
        'role': 'borrowed',
        'limit': '100',
      });
    });
  });

  group('слой 2 — ответ сервера с ошибкой', () {
    test('400 VALIDATION_ERROR → русский текст, это НЕ отказ сети', () async {
      final repo = HttpLoanRepository(
        api(
          (_) async => json({
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'The book is already lent',
            },
          }, 400),
        ),
      );
      final result = await repo.create(
        Loan.request(bookId: 1, dueDate: DateTime(2026, 11, 1)),
      );
      final err = result as Err<Loan>;
      expect(err.msg, 'Книгу уже выдали — выберите другую');
      expect(err.isNetwork, isFalse); // кэш такую ошибку подменять не должен
    });

    test('404 → «Запись не существует»', () async {
      final repo = HttpBookRepository(
        api(
          (_) async => json({
            'error': {'code': 'NOT_FOUND', 'message': 'Book not found'},
          }, 404),
        ),
      );
      expect((await repo.fetchById(99) as Err).msg, 'Запись не существует');
    });

    test('401 → токен стёрт, корень извещён (уйдёт на вход)', () async {
      final repo = HttpBookRepository(
        api(
          (_) async => json({
            'error': {'code': 'UNAUTHORIZED', 'message': 'Token expired'},
          }, 401),
        ),
      );
      final result = await repo.fetchAll();
      expect((result as Err).msg, 'Сессия истекла — войдите снова');
      expect(unauthorized, 1);
      expect(await TokenStore().read(), isNull);
    });
  });

  group('слой 1 — не дошли до сервера (isNetwork)', () {
    Future<Err> failWith(Object error) async {
      final repo = HttpBookRepository(api((_) async => throw error));
      return await repo.fetchAll() as Err;
    }

    test('SocketException — нет сети', () async {
      final err = await failWith(const SocketException('Connection refused'));
      expect(err.msg, 'Нет сети — повторите попытку');
      expect(err.isNetwork, isTrue);
    });

    test('ClientException — тоже нет сети', () async {
      final err = await failWith(http.ClientException('Connection closed'));
      expect(err.isNetwork, isTrue);
    });

    test('TimeoutException — сервер не отвечает', () async {
      final err = await failWith(TimeoutException('8s'));
      expect(err.msg, 'Сервер не отвечает');
      expect(err.isNetwork, isTrue);
    });
  });

  group('слой 3 — тело-сюрприз', () {
    test('200, но не JSON', () async {
      final repo = HttpBookRepository(
        api((_) async => http.Response('<html>proxy</html>', 200)),
      );
      final err = await repo.fetchAll() as Err;
      expect(err.msg, 'Ответ не тот, что обещан');
      expect(err.isNetwork, isFalse);
    });

    test('200, JSON, но без items / не та форма книги', () async {
      final noItems = HttpBookRepository(
        api((_) async => json({'data': []}, 200)),
      );
      expect((await noItems.fetchAll() as Err).msg, 'Ответ не тот, что обещан');

      final badBook = HttpBookRepository(
        api((_) async => json({'id': 'seven'}, 200)),
      );
      expect(
        (await badBook.fetchById(7) as Err).msg,
        'Ответ не тот, что обещан',
      );
    });
  });
}
