/// Статус обмена: книга ещё у заёмщика или уже возвращена.
enum LoanStatus {
  active('Активен'),
  returned('Возвращён');

  const LoanStatus(this.label);
  final String label;
}

/// Обмен — доменная модель по ТЗ: Loan(id, bookId, borrowerId, startDate,
/// dueDate, status). Названия и имена нужны только для отображения.
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

  /// Черновик запроса «хочу эту книгу до такой-то даты»: остальное
  /// (id, заёмщика, дату начала) заполнит хранилище (на L5 — сервер).
  Loan.request({required this.bookId, required this.dueDate})
    : id = 0,
      bookTitle = '',
      bookAuthor = '',
      ownerId = 0,
      ownerName = '',
      borrowerId = 0,
      borrowerName = '',
      startDate = DateTime.now(),
      status = LoanStatus.active;

  /// Книга ещё не возвращена, а срок уже прошёл.
  bool get isOverdue =>
      status == LoanStatus.active && dueDate.isBefore(DateTime.now());

  Loan copyWith({int? id, LoanStatus? status}) => Loan(
    id: id ?? this.id,
    bookId: bookId,
    bookTitle: bookTitle,
    bookAuthor: bookAuthor,
    ownerId: ownerId,
    ownerName: ownerName,
    borrowerId: borrowerId,
    borrowerName: borrowerName,
    startDate: startDate,
    dueDate: dueDate,
    status: status ?? this.status,
  );
}
