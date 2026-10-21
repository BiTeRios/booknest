import 'dart:async';

import 'package:booknest/data/book.dart';
import 'package:booknest/data/book_repository.dart';
import 'package:booknest/data/loan.dart';
import 'package:booknest/data/loan_repository.dart';
import 'package:booknest/data/result.dart';

// Подставные хранилища для тестов (L6): те же интерфейсы, что у HTTP-хранилищ,
// но данные в памяти и ответ решает тест. Модели и экраны разницы не видят —
// ради этого интерфейс и вводился на L4.

/// Книга для тестов: обязательные поля заполнены разумно.
Book book(
  int id, {
  String? title,
  String genre = 'Классика',
  BookStatus status = BookStatus.available,
  int ownerId = 1,
}) => Book(
  id: id,
  ownerId: ownerId,
  ownerName: 'Владелец $ownerId',
  title: title ?? 'Книга $id',
  author: 'Автор $id',
  genre: genre,
  status: status,
);

/// Обмен для тестов.
Loan loan(
  int id, {
  int bookId = 1,
  LoanStatus status = LoanStatus.active,
  DateTime? dueDate,
}) => Loan(
  id: id,
  bookId: bookId,
  bookTitle: 'Книга $bookId',
  bookAuthor: 'Автор $bookId',
  ownerId: 1,
  ownerName: 'Владелец',
  borrowerId: 2,
  borrowerName: 'Заёмщик',
  startDate: DateTime(2026, 10, 1),
  dueDate: dueDate ?? DateTime(2026, 11, 1),
  status: status,
);

const networkDown = Err<Never>('Нет сети — повторите попытку', isNetwork: true);

class FakeBookRepository implements BookRepository {
  FakeBookRepository([List<Book> books = const []]) : books = [...books];

  /// «Сервер» — тест может менять его между вызовами.
  final List<Book> books;

  /// Если задан — fetchAll отвечает этой ошибкой.
  Err<List<Book>>? listError;

  /// Если задан — мутации отвечают этой ошибкой.
  Err<Never>? writeError;

  /// Если задан — fetchAll ждёт, пока тест не завершит Completer
  /// (так видно состояние «грузится»).
  Completer<void>? gate;

  /// Журнал запросов списка: какие страницы и фильтры просила модель.
  final fetches =
      <({BookScope scope, int page, String? search, String? genre})>[];

  int _nextId = 100;

  @override
  Future<Result<List<Book>>> fetchAll({
    BookScope scope = BookScope.mine,
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
  }) async {
    fetches.add((scope: scope, page: page, search: search, genre: genre));
    if (gate case final g?) await g.future;
    if (listError case final e?) return e;
    final q = search?.toLowerCase() ?? '';
    final found = books.where(
      (b) =>
          (genre == null || b.genre == genre) &&
          (q.isEmpty || b.title.toLowerCase().contains(q)),
    );
    return Ok(found.skip((page - 1) * limit).take(limit).toList());
  }

  @override
  Future<Result<Book>> fetchById(int id) async {
    final found = books.where((b) => b.id == id).firstOrNull;
    return found == null ? const Err('Запись не существует') : Ok(found);
  }

  @override
  Future<Result<Book>> create(Book draft) async {
    if (writeError case final e?) return e;
    final created = draft.copyWith(id: _nextId++, ownerId: 1);
    books.insert(0, created);
    return Ok(created);
  }

  @override
  Future<Result<Book>> update(Book book) async {
    if (writeError case final e?) return e;
    return Ok(book);
  }

  @override
  Future<Result<void>> delete(int id) async {
    if (writeError case final e?) return e;
    books.removeWhere((b) => b.id == id);
    return const Ok(null);
  }
}

class FakeLoanRepository implements LoanRepository {
  FakeLoanRepository({
    List<Loan> lent = const [],
    List<Loan> borrowed = const [],
  }) : lent = [...lent],
       borrowed = [...borrowed];

  final List<Loan> lent;
  final List<Loan> borrowed;

  /// Ошибка списка для конкретной роли (одна роль может упасть, другая — нет).
  final listErrors = <LoanRole, Err<List<Loan>>>{};
  Err<Never>? writeError;

  int _nextId = 100;

  @override
  Future<Result<List<Loan>>> fetchAll({required LoanRole role}) async {
    if (listErrors[role] case final e?) return e;
    return Ok(role == LoanRole.lent ? [...lent] : [...borrowed]);
  }

  @override
  Future<Result<Loan>> fetchById(int id) async =>
      const Err('Запись не существует');

  @override
  Future<Result<Loan>> create(Loan draft) async {
    if (writeError case final e?) return e;
    return Ok(loan(_nextId++, bookId: draft.bookId, dueDate: draft.dueDate));
  }

  @override
  Future<Result<Loan>> update(Loan loan) async {
    if (writeError case final e?) return e;
    return Ok(loan);
  }

  @override
  Future<Result<void>> delete(int id) async => const Ok(null);
}
