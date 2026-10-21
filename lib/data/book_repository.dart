import 'book.dart';
import 'result.dart';

/// Чьи книги просим: свои («Моя библиотека») или чужие («Книги сообщества»).
/// Кто «я», решает источник: mock — по константе, на L5 сервер — по JWT.
enum BookScope { mine, community }

/// Контракт хранилища книг: ЧТО можно просить, а не КАК.
/// На L5 каждый метод один-к-одному ложится на REST backend-а:
///   fetchAll  → GET    /books?scope=…
///   fetchById → GET    /books/{id}      (404 → Err «не существует»)
///   create    → POST   /books           (201, id даёт сервер)
///   update    → PUT    /books/{id}
///   delete    → DELETE /books/{id}      (204, пустое тело → `Result<void>`)
abstract class BookRepository {
  /// L5: интерфейс вырос совместимо — пагинация и поиск на сервере через
  /// опциональные именованные параметры; старый вызов fetchAll() не сломан.
  Future<Result<List<Book>>> fetchAll({
    BookScope scope = BookScope.mine,
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
  });
  Future<Result<Book>> fetchById(int id);
  Future<Result<Book>> create(Book book);
  Future<Result<Book>> update(Book book);
  Future<Result<void>> delete(int id);
}
