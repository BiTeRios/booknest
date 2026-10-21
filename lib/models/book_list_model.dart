import 'package:flutter/foundation.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../data/result.dart';

/// Состояние списка книг + фильтры + триада «грузится / данные / ошибка».
/// Хранилище входит через конструктор (простой DI): модель не знает и не должна
/// знать, откуда приходят данные — тип поля это ИНТЕРФЕЙС, а не mock.
abstract class BookListModel extends ChangeNotifier {
  BookListModel(this._repository, this.scope);

  final BookRepository _repository;
  final BookScope scope;

  /// Размер ломтя: телефон получает с сервера только свою страницу.
  static const pageSize = 10;

  bool _loading = false;
  String? _error;
  List<Book> _books = const [];
  String _query = '';
  String? _genre;

  // Пагинация (L5): сколько страниц уже приклеено и есть ли ещё.
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  String? _loadMoreError;

  bool get isLoading => _loading;
  String? get error => _error;
  String get query => _query;
  String? get genre => _genre;
  bool get hasMore => _hasMore;
  String? get loadMoreError => _loadMoreError;

  /// Все загруженные книги — только для чтения: мутация идёт через методы,
  /// которые извещают подписчиков.
  List<Book> get books => List.unmodifiable(_books);

  /// То, что видит экран. Поиск и жанр с L5 фильтрует сервер, поэтому это
  /// просто загруженные страницы.
  List<Book> get visibleBooks => books;

  /// Ищет в загруженном списке; null — если такой книги нет.
  Book? byId(int id) => _books.where((b) => b.id == id).firstOrNull;

  /// Первая страница с текущими фильтрами; retry сохраняет фильтр.
  Future<void> load() async {
    _loading = true;
    _error = null;
    _loadMoreError = null;
    _page = 1;
    notifyListeners(); // подписанные экраны входят в состояние «грузится»
    switch (await _fetchPage(1)) {
      case Ok(:final value):
        _books = value;
        _hasMore =
            value.length == pageSize; // полная страница → видимо, есть ещё
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners(); // …и выходят: с данными или с ошибкой — никогда молча
  }

  /// Следующая страница приклеивается к списку. Зовётся из itemBuilder-а,
  /// то есть в разгар build: поэтому флаг ставится БЕЗ notifyListeners()
  /// (иначе «setState() called during build»), а guard не даёт двойных страниц.
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasMore || _loadMoreError != null) return;
    _loadingMore = true;
    switch (await _fetchPage(_page + 1)) {
      case Ok(:final value):
        _page += 1;
        _books = [..._books, ...value];
        _hasMore = value.length == pageSize;
      case Err(:final msg):
        _loadMoreError = msg; // хвост списка покажет ошибку и «Повторить»
    }
    _loadingMore = false;
    notifyListeners();
  }

  /// «Повторить» в хвосте списка после неудачной догрузки.
  void retryLoadMore() {
    _loadMoreError = null;
    notifyListeners();
  }

  Future<Result<List<Book>>> _fetchPage(int page) => _repository.fetchAll(
    scope: scope,
    page: page,
    limit: pageSize,
    search: _query,
    genre: _genre,
  );

  /// Поиск идёт на сервере: новый запрос с первой страницы.
  Future<void> search(String query) {
    _query = query.trim();
    return load();
  }

  Future<void> setGenre(String? genre) {
    _genre = genre;
    return load();
  }

  // Мутации: вердикт хранилища → изменение → извещение.
  // Возврат как у validator-а: null — успех, строка — сообщение об ошибке.

  Future<String?> add(Book draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        // с id, полученным от хранилища; сервер отдаёт новые первыми
        _books = [value, ..._books];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg; // состояние нетронуто — экран решает, что показать
    }
  }

  Future<String?> update(Book book) async {
    switch (await _repository.update(book)) {
      case Ok(:final value):
        _books = [for (final b in _books) b.id == value.id ? value : b];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _books = _books.where((b) => b.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  /// Хранилище уже сменило статус книги (обмен создан или закрыт) —
  /// модель синхронизируется локально, без повторной загрузки списка.
  void markStatus(int bookId, BookStatus status) {
    _books = [
      for (final b in _books) b.id == bookId ? b.copyWith(status: status) : b,
    ];
    notifyListeners();
  }
}

/// «Моя библиотека»: книги текущего пользователя.
class LibraryModel extends BookListModel {
  LibraryModel(BookRepository repository) : super(repository, BookScope.mine);
}

/// «Книги сообщества»: книги других пользователей.
class CommunityModel extends BookListModel {
  CommunityModel(BookRepository repository)
    : super(repository, BookScope.community);
}
