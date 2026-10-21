import 'api_client.dart';
import 'book.dart';
import 'book_repository.dart';
import 'result.dart';

/// Вторая реализация интерфейса L4 — книги на backend-е.
/// Интерфейс не изменился: каждый метод — свой маршрут из таблицы контракта.
class HttpBookRepository implements BookRepository {
  HttpBookRepository(this._api);

  final ApiClient _api;

  static Book _book(Object? json) =>
      Book.fromJson(json as Map<String, dynamic>);

  @override
  Future<Result<List<Book>>> fetchAll({
    BookScope scope = BookScope.mine,
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
  }) => _api.send(
    'GET',
    '/books',
    query: {
      'scope': scope.name, // кто «я» — сервер знает по JWT
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.isNotEmpty) 'search': search,
      'genre': ?genre, // null-aware элемент: ключ попадает, только если не null
    },
    okStatus: 200,
    parse: (json) => ApiClient.items(json, Book.fromJson), // конверт!
  );

  @override
  Future<Result<Book>> fetchById(int id) =>
      _api.send('GET', '/books/$id', okStatus: 200, parse: _book); // 404 → Err

  @override
  Future<Result<Book>> create(Book book) => _api.send(
    'POST',
    '/books',
    body: book.toJson(),
    okStatus: 201, // id даёт сервер — он в ответе
    parse: _book,
  );

  @override
  Future<Result<Book>> update(Book book) => _api.send(
    'PUT',
    '/books/${book.id}',
    body: book.toJson(),
    okStatus: 200,
    parse: _book,
  );

  @override
  Future<Result<void>> delete(int id) => _api.send(
    'DELETE',
    '/books/$id',
    okStatus: 204, // пустое тело → Result<void>
    parse: (_) {},
  );
}
