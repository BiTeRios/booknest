// Зашитые в код данные для статического UI (L2), общие для нескольких экранов.
// Поля моделей повторяют модель данных backend-а из ТЗ темы:
//   Book(id, ownerId, title, author, genre, coverUrl, status)
//   Loan(id, bookId, borrowerId, startDate, dueDate, status)
// Имена (ownerName, borrowerName, bookTitle) нужны только для отображения.

/// Статус книги: доступна для обмена или сейчас у кого-то на руках.
enum BookStatus {
  available('Доступна'),
  lent('Выдана');

  const BookStatus(this.label);
  final String label;
}

/// Статус обмена: книга ещё у заёмщика или уже возвращена.
enum LoanStatus {
  active('Активен'),
  returned('Возвращён');

  const LoanStatus(this.label);
  final String label;
}

/// Пользователь приложения (на L5 приходит из POST /auth/login).
class AppUser {
  final int id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});
}

class Book {
  final int id;
  final int ownerId;
  final String ownerName;
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
}

class Loan {
  final int id;
  final int bookId;
  final String bookTitle;
  final String bookAuthor;
  final int ownerId;
  final String ownerName;
  final int borrowerId;
  final String borrowerName;
  final DateTime startDate;
  final DateTime dueDate;
  final LoanStatus status;

  const Loan({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.ownerId,
    required this.ownerName,
    required this.borrowerId,
    required this.borrowerName,
    required this.startDate,
    required this.dueDate,
    this.status = LoanStatus.active,
  });

  /// Книга ещё не возвращена, а срок уже прошёл.
  bool get isOverdue =>
      status == LoanStatus.active && dueDate.isBefore(DateTime.now());
}

const currentUser = AppUser(
  id: 1,
  name: 'Vitalii Liogchi',
  email: 'v.liogchi@booknest.md',
);

const bookGenres = [
  'Классика',
  'Фантастика',
  'Фэнтези',
  'Антиутопия',
  'Детектив',
  'Нон-фикшн',
  'IT',
];

/// Моя библиотека: книги текущего пользователя.
const mockMyBooks = [
  Book(
    id: 1,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: 'Мастер и Маргарита',
    author: 'Михаил Булгаков',
    genre: 'Классика',
  ),
  Book(
    id: 2,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: '1984',
    author: 'Джордж Оруэлл',
    genre: 'Антиутопия',
    status: BookStatus.lent,
  ),
  Book(
    id: 3,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: 'Ion',
    author: 'Liviu Rebreanu',
    genre: 'Классика',
  ),
  Book(
    id: 4,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: 'Чистый код. Создание, анализ и рефакторинг',
    author: 'Роберт Мартин',
    genre: 'IT',
  ),
  Book(
    id: 5,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: 'Дюна',
    author: 'Фрэнк Герберт',
    genre: 'Фантастика',
    status: BookStatus.lent,
  ),
  Book(
    id: 6,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: 'Sapiens. Краткая история человечества',
    author: 'Юваль Ной Харари',
    genre: 'Нон-фикшн',
  ),
  Book(
    id: 7,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: 'Убийство в «Восточном экспрессе»',
    author: 'Агата Кристи',
    genre: 'Детектив',
  ),
  Book(
    id: 8,
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    title: 'Гарри Поттер и философский камень',
    author: 'Джоан Роулинг',
    genre: 'Фэнтези',
    status: BookStatus.lent,
  ),
];

/// Книги других пользователей (список сообщества).
const mockCommunityBooks = [
  Book(
    id: 9,
    ownerId: 2,
    ownerName: 'Ana Rusu',
    title: 'Преступление и наказание',
    author: 'Фёдор Достоевский',
    genre: 'Классика',
  ),
  Book(
    id: 10,
    ownerId: 3,
    ownerName: 'Ion Popescu',
    title: 'Автостопом по галактике',
    author: 'Дуглас Адамс',
    genre: 'Фантастика',
  ),
  Book(
    id: 11,
    ownerId: 4,
    ownerName: 'Maria Ceban',
    title: 'Алгоритмы. Построение и анализ',
    author: 'Томас Кормен и др.',
    genre: 'IT',
    status: BookStatus.lent,
  ),
  Book(
    id: 12,
    ownerId: 5,
    ownerName: 'Dan Țurcanu',
    title: 'Властелин колец. Братство Кольца',
    author: 'Джон Р. Р. Толкин',
    genre: 'Фэнтези',
  ),
  Book(
    id: 13,
    ownerId: 4,
    ownerName: 'Maria Ceban',
    title: 'Маленький принц',
    author: 'Антуан де Сент-Экзюпери',
    genre: 'Классика',
  ),
  Book(
    id: 14,
    ownerId: 3,
    ownerName: 'Ion Popescu',
    title: 'О дивный новый мир',
    author: 'Олдос Хаксли',
    genre: 'Антиутопия',
  ),
  Book(
    id: 15,
    ownerId: 2,
    ownerName: 'Ana Rusu',
    title: 'Думай медленно… решай быстро',
    author: 'Даниэль Канеман',
    genre: 'Нон-фикшн',
    status: BookStatus.lent,
  ),
  Book(
    id: 16,
    ownerId: 5,
    ownerName: 'Dan Țurcanu',
    title: 'Шерлок Холмс. Собака Баскервилей',
    author: 'Артур Конан Дойл',
    genre: 'Детектив',
    status: BookStatus.lent,
  ),
];

/// Обмены, где текущий пользователь — владелец книги (выданные).
final mockLentLoans = [
  Loan(
    id: 1,
    bookId: 2,
    bookTitle: '1984',
    bookAuthor: 'Джордж Оруэлл',
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    borrowerId: 2,
    borrowerName: 'Ana Rusu',
    startDate: DateTime(2026, 10, 1),
    dueDate: DateTime(2026, 10, 29),
  ),
  Loan(
    id: 2,
    bookId: 5,
    bookTitle: 'Дюна',
    bookAuthor: 'Фрэнк Герберт',
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    borrowerId: 3,
    borrowerName: 'Ion Popescu',
    startDate: DateTime(2026, 10, 10),
    dueDate: DateTime(2026, 11, 7),
  ),
  Loan(
    id: 3,
    bookId: 8,
    bookTitle: 'Гарри Поттер и философский камень',
    bookAuthor: 'Джоан Роулинг',
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    borrowerId: 4,
    borrowerName: 'Maria Ceban',
    startDate: DateTime(2026, 10, 14),
    dueDate: DateTime(2026, 11, 4),
  ),
  Loan(
    id: 4,
    bookId: 1,
    bookTitle: 'Мастер и Маргарита',
    bookAuthor: 'Михаил Булгаков',
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    borrowerId: 4,
    borrowerName: 'Maria Ceban',
    startDate: DateTime(2026, 9, 1),
    dueDate: DateTime(2026, 9, 22),
    status: LoanStatus.returned,
  ),
  Loan(
    id: 5,
    bookId: 4,
    bookTitle: 'Чистый код. Создание, анализ и рефакторинг',
    bookAuthor: 'Роберт Мартин',
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    borrowerId: 5,
    borrowerName: 'Dan Țurcanu',
    startDate: DateTime(2026, 8, 15),
    dueDate: DateTime(2026, 9, 1),
    status: LoanStatus.returned,
  ),
  Loan(
    id: 6,
    bookId: 6,
    bookTitle: 'Sapiens. Краткая история человечества',
    bookAuthor: 'Юваль Ной Харари',
    ownerId: 1,
    ownerName: 'Vitalii Liogchi',
    borrowerId: 3,
    borrowerName: 'Ion Popescu',
    startDate: DateTime(2026, 9, 5),
    dueDate: DateTime(2026, 9, 26),
    status: LoanStatus.returned,
  ),
];

/// Обмены, где текущий пользователь — заёмщик (взятые).
final mockBorrowedLoans = [
  Loan(
    id: 7,
    bookId: 11,
    bookTitle: 'Алгоритмы. Построение и анализ',
    bookAuthor: 'Томас Кормен и др.',
    ownerId: 4,
    ownerName: 'Maria Ceban',
    borrowerId: 1,
    borrowerName: 'Vitalii Liogchi',
    startDate: DateTime(2026, 10, 5),
    dueDate: DateTime(2026, 11, 2),
  ),
  Loan(
    id: 8,
    bookId: 15,
    bookTitle: 'Думай медленно… решай быстро',
    bookAuthor: 'Даниэль Канеман',
    ownerId: 2,
    ownerName: 'Ana Rusu',
    borrowerId: 1,
    borrowerName: 'Vitalii Liogchi',
    startDate: DateTime(2026, 9, 28),
    dueDate: DateTime(2026, 10, 19),
  ),
  Loan(
    id: 9,
    bookId: 16,
    bookTitle: 'Шерлок Холмс. Собака Баскервилей',
    bookAuthor: 'Артур Конан Дойл',
    ownerId: 5,
    ownerName: 'Dan Țurcanu',
    borrowerId: 1,
    borrowerName: 'Vitalii Liogchi',
    startDate: DateTime(2026, 10, 12),
    dueDate: DateTime(2026, 10, 26),
  ),
  Loan(
    id: 10,
    bookId: 13,
    bookTitle: 'Маленький принц',
    bookAuthor: 'Антуан де Сент-Экзюпери',
    ownerId: 4,
    ownerName: 'Maria Ceban',
    borrowerId: 1,
    borrowerName: 'Vitalii Liogchi',
    startDate: DateTime(2026, 9, 10),
    dueDate: DateTime(2026, 9, 24),
    status: LoanStatus.returned,
  ),
  Loan(
    id: 11,
    bookId: 10,
    bookTitle: 'Автостопом по галактике',
    bookAuthor: 'Дуглас Адамс',
    ownerId: 3,
    ownerName: 'Ion Popescu',
    borrowerId: 1,
    borrowerName: 'Vitalii Liogchi',
    startDate: DateTime(2026, 8, 20),
    dueDate: DateTime(2026, 9, 5),
    status: LoanStatus.returned,
  ),
  Loan(
    id: 12,
    bookId: 14,
    bookTitle: 'О дивный новый мир',
    bookAuthor: 'Олдос Хаксли',
    ownerId: 3,
    ownerName: 'Ion Popescu',
    borrowerId: 1,
    borrowerName: 'Vitalii Liogchi',
    startDate: DateTime(2026, 7, 1),
    dueDate: DateTime(2026, 7, 21),
    status: LoanStatus.returned,
  ),
];
