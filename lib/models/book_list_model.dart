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

  bool _loading = false;
  String? _error;
  List<Book> _books = const [];
  String _query = '';
  String? _genre;

  bool get isLoading => _loading;
  String? get error => _error;
  String get query => _query;
  String? get genre => _genre;

  /// Все загруженные книги — только для чтения: мутация идёт через методы,
  /// которые извещают подписчиков.
  List<Book> get books => List.unmodifiable(_books);

  /// Книги после поиска и фильтра по жанру — то, что видит экран.
  List<Book> get visibleBooks {
    final q = _query.trim().toLowerCase();
    return List.unmodifiable(
      _books.where(
        (b) =>
            (_genre == null || b.genre == _genre) &&
            (q.isEmpty ||
                b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q)),
      ),
    );
  }

  /// Ищет в загруженном списке; null — если такой книги нет.
  Book? byId(int id) => _books.where((b) => b.id == id).firstOrNull;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners(); // подписанные экраны входят в состояние «грузится»
    switch (await _repository.fetchAll(scope: scope)) {
      case Ok(:final value):
        _books = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners(); // …и выходят: с данными или с ошибкой — никогда молча
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void setGenre(String? genre) {
    _genre = genre;
    notifyListeners();
  }

  // Мутации: вердикт хранилища → изменение → извещение.
  // Возврат как у validator-а: null — успех, строка — сообщение об ошибке.

  Future<String?> add(Book draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _books = [..._books, value]; // с id, полученным от хранилища
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
