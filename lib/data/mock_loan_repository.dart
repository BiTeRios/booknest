import 'book.dart';
import 'loan.dart';
import 'loan_repository.dart';
import 'mock_book_repository.dart';
import 'mock_data.dart';
import 'result.dart';

/// Хранилище обменов в памяти. Знает о хранилище книг, потому что обмен
/// меняет статус книги — на L5 то же самое делает сервер в одной транзакции.
class MockLoanRepository implements LoanRepository {
  MockLoanRepository(this._books);

  final MockBookRepository _books;
  final List<Loan> _loans = [...mockLentLoans, ...mockBorrowedLoans];
  int _nextId = 1000;

  bool simulateError = false;

  static const _latency = Duration(milliseconds: 800);
  static const _errNetwork = 'Сервер не отвечает — повторите попытку';
  static const _errNotFound = 'Обмен не существует';

  Future<bool> _networkFails() async {
    await Future.delayed(_latency);
    return simulateError;
  }

  @override
  Future<Result<List<Loan>>> fetchAll({required LoanRole role}) async {
    if (await _networkFails()) return const Err(_errNetwork);
    return Ok(
      _loans
          .where(
            (l) => role == LoanRole.lent
                ? l.ownerId == mockUserId
                : l.borrowerId == mockUserId,
          )
          .toList(),
    );
  }

  @override
  Future<Result<Loan>> fetchById(int id) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final index = _loans.indexWhere((l) => l.id == id);
    if (index == -1) return const Err(_errNotFound);
    return Ok(_loans[index]);
  }

  @override
  Future<Result<Loan>> create(Loan draft) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final book = _books.find(draft.bookId);
    if (book == null) return const Err('Книга не существует');
    if (book.ownerId == mockUserId) {
      return const Err('Свою книгу запросить нельзя');
    }
    if (book.status != BookStatus.available) {
      return const Err('Книгу уже выдали — выберите другую');
    }
    final now = DateTime.now();
    final created = Loan(
      id: _nextId++,
      bookId: book.id,
      bookTitle: book.title,
      bookAuthor: book.author,
      ownerId: book.ownerId,
      ownerName: book.ownerName,
      borrowerId: mockUserId, // заёмщик — тот, кто вошёл
      borrowerName: mockUserName,
      startDate: DateTime(now.year, now.month, now.day),
      dueDate: draft.dueDate,
    );
    _loans.add(created);
    _books.setStatus(book.id, BookStatus.lent);
    return Ok(created);
  }

  @override
  Future<Result<Loan>> update(Loan loan) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final index = _loans.indexWhere((l) => l.id == loan.id);
    if (index == -1) return const Err(_errNotFound);
    _loans[index] = loan;
    if (loan.status == LoanStatus.returned) {
      // книга снова свободна для обмена
      _books.setStatus(loan.bookId, BookStatus.available);
    }
    return Ok(loan);
  }

  @override
  Future<Result<void>> delete(int id) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final before = _loans.length;
    _loans.removeWhere((l) => l.id == id);
    if (_loans.length == before) return const Err(_errNotFound);
    return const Ok(null);
  }
}
