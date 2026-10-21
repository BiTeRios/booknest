import 'book.dart';
import 'book_repository.dart';
import 'offline_cache.dart';
import 'result.dart';

/// Источник ответа на список: сервер (null) или кэш с моментом сохранения.
typedef SourceListener = void Function(DateTime? cachedAt);

/// Декоратор (L6): та же BookRepository, но списки переживают отсутствие сети.
/// Успешный ответ сервера сохраняется в кэш; если до сервера не дошли
/// (Err.isNetwork), отдаётся последний сохранённый снимок того же запроса.
/// Ответ сервера с ошибкой (400/404/…) кэш не подменяет — это не «нет сети».
/// Модели и экраны декоратора не замечают: он входит в корне композиции.
class CachedBookRepository implements BookRepository {
  CachedBookRepository(this._remote, this._cache, {this.onSource});

  final BookRepository _remote;
  final OfflineCache _cache;

  /// Корень узнаёт, откуда пришли данные, — для баннера «офлайн».
  final SourceListener? onSource;

  @override
  Future<Result<List<Book>>> fetchAll({
    BookScope scope = BookScope.mine,
    int page = 1,
    int limit = 20,
    String? search,
    String? genre,
  }) async {
    final key =
        'books:${scope.name}:$page:$limit:${search ?? ''}:${genre ?? ''}';
    final result = await _remote.fetchAll(
      scope: scope,
      page: page,
      limit: limit,
      search: search,
      genre: genre,
    );
    switch (result) {
      case Ok(:final value):
        onSource?.call(null);
        await _cache.putList(key, [for (final b in value) b.toStorageJson()]);
        return result;
      case Err(isNetwork: true):
        final cached = await _cache.getList(key, Book.fromJson);
        if (cached == null) return result; // кэша нет — честная ошибка
        onSource?.call(cached.savedAt);
        return Ok(cached.items);
      case Err():
        return result;
    }
  }

  // Изменения — только онлайн: без сети пользователь увидит ошибку и сможет
  // повторить. Очередь офлайн-изменений — вне рамок лабораторной.

  @override
  Future<Result<Book>> fetchById(int id) => _remote.fetchById(id);

  @override
  Future<Result<Book>> create(Book book) => _remote.create(book);

  @override
  Future<Result<Book>> update(Book book) => _remote.update(book);

  @override
  Future<Result<void>> delete(int id) => _remote.delete(id);
}
