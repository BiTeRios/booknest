import 'book.dart';
import 'book_repository.dart';
import 'mock_data.dart';
import 'result.dart';

/// Хранилище книг в памяти — с повадками сети: задержка и переключаемая авария.
class MockBookRepository implements BookRepository {
  final List<Book> _books = [
    ...mockMyBooks,
    ...mockCommunityBooks,
  ]; // seed из L2
  int _nextId = 1000; // выше любого id из seed-а

  /// Авария: включена → любой вызов проваливается (переключатель в профиле).
  bool simulateError = false;

  static const _latency = Duration(milliseconds: 800);
  static const _errNetwork = 'Сервер не отвечает — повторите попытку';
  static const _errNotFound = 'Книга не существует';

  /// Пролог каждого метода: сеть не отвечает мгновенно — и мы не будем.
  Future<bool> _networkFails() async {
    await Future.delayed(_latency);
    return simulateError;
  }

  @override
  Future<Result<List<Book>>> fetchAll({
    BookScope scope = BookScope.mine,
  }) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final mine = scope == BookScope.mine;
    // копия — внутренность хранилища не отдаётся из рук
    return Ok(_books.where((b) => (b.ownerId == mockUserId) == mine).toList());
  }

  @override
  Future<Result<Book>> fetchById(int id) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final index = _books.indexWhere((b) => b.id == id);
    if (index == -1) return const Err(_errNotFound); // «404» mock-а
    return Ok(_books[index]);
  }

  @override
  Future<Result<Book>> create(Book book) async {
    if (await _networkFails()) return const Err(_errNetwork);
    // id и владельца даёт ХРАНИЛИЩЕ, а не форма
    final created = book.copyWith(
      id: _nextId++,
      ownerId: mockUserId,
      ownerName: mockUserName,
      status: BookStatus.available,
    );
    _books.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Book>> update(Book book) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index == -1) return const Err(_errNotFound);
    _books[index] = book; // заменяет по id
    return Ok(book);
  }

  @override
  Future<Result<void>> delete(int id) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final before = _books.length;
    _books.removeWhere((b) => b.id == id);
    if (_books.length == before) return const Err(_errNotFound);
    return const Ok(null); // «удалил, отдать нечего» — 204 в типах
  }

  // --- Внутреннее для MockLoanRepository: так же сервер сам меняет статус
  // книги, когда создаётся или закрывается обмен. Не часть интерфейса.

  Book? find(int id) => _books.where((b) => b.id == id).firstOrNull;

  void setStatus(int bookId, BookStatus status) {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index != -1) _books[index] = _books[index].copyWith(status: status);
  }
}
