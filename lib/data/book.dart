/// Статус книги: доступна для обмена или сейчас у кого-то на руках.
enum BookStatus {
  available('Доступна'),
  lent('Выдана');

  const BookStatus(this.label);
  final String label;
}

/// Жанры, из которых выбирает форма книги и фильтр списков.
const bookGenres = [
  'Классика',
  'Фантастика',
  'Фэнтези',
  'Антиутопия',
  'Детектив',
  'Нон-фикшн',
  'IT',
];

/// Книга — доменная модель по ТЗ: Book(id, ownerId, title, author, genre,
/// coverUrl, status). Mock умрёт на L5, а этот файл останется и выучит JSON.
class Book {
  final int id;
  final int ownerId;
  final String ownerName; // только для отображения в списке сообщества
  final String title;
  final String author;
  final String genre;
  final String? coverUrl; // обложка загружается на L5 через POST /files
  final BookStatus status;

  const Book({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.author,
    required this.genre,
    this.coverUrl,
    this.status = BookStatus.available,
  });

  /// Черновик из формы: id и владельца даст хранилище (на L5 — сервер).
  const Book.draft({
    required this.title,
    required this.author,
    required this.genre,
    this.coverUrl,
  }) : id = 0,
       ownerId = 0,
       ownerName = '',
       status = BookStatus.available;

  /// «Та же книга, но с другими полями» — объекты неизменяемы.
  Book copyWith({
    int? id,
    int? ownerId,
    String? ownerName,
    String? title,
    String? author,
    String? genre,
    String? coverUrl,
    BookStatus? status,
  }) => Book(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    ownerName: ownerName ?? this.ownerName,
    title: title ?? this.title,
    author: author ?? this.author,
    genre: genre ?? this.genre,
    coverUrl: coverUrl ?? this.coverUrl,
    status: status ?? this.status,
  );

  // --- Граница JSON (L5): язык сервера ⇄ доменная модель.

  /// Тело ответа сервера → книга. Неожиданная форма тела бросает
  /// TypeError/FormatException — хранилище переводит это в Err.
  factory Book.fromJson(Map<String, dynamic> j) => Book(
    id: j['id'] as int,
    ownerId: j['ownerId'] as int,
    ownerName: j['ownerName'] as String? ?? '',
    title: j['title'] as String,
    author: j['author'] as String,
    genre: j['genre'] as String? ?? '',
    coverUrl: j['coverUrl'] as String?,
    status: BookStatus.values.asNameMap()[j['status']] ?? BookStatus.available,
  );

  /// Книга → тело POST/PUT. Без id, владельца и статуса: идентичность
  /// и владельца даёт сервер, статус меняют только обмены.
  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'genre': genre,
    'coverUrl': coverUrl,
  };

  /// Полный снимок для offline-кэша (L6): все поля, которые читает fromJson.
  Map<String, dynamic> toStorageJson() => {
    'id': id,
    'ownerId': ownerId,
    'ownerName': ownerName,
    ...toJson(),
    'status': status.name,
  };
}
