import 'package:flutter/foundation.dart';

import '../data/book.dart';
import '../data/loan.dart';
import '../data/loan_repository.dart';
import '../data/result.dart';

/// Состояние «Моих обменов»: выданные и взятые книги + триада загрузки.
class LoansModel extends ChangeNotifier {
  LoansModel(this._repository);

  final LoanRepository _repository; // тип — интерфейс

  bool _loading = false;
  String? _error;
  List<Loan> _lent = const [];
  List<Loan> _borrowed = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Loan> get lent => List.unmodifiable(_lent);
  List<Loan> get borrowed => List.unmodifiable(_borrowed);

  /// Активные обмены — число на бейдже вкладки «Обмены».
  int get activeCount => [
    ..._lent,
    ..._borrowed,
  ].where((l) => l.status == LoanStatus.active).length;

  /// Текущий обмен книги (у кого она сейчас), если книга выдана.
  Loan? activeLoanFor(int bookId) => [..._lent, ..._borrowed]
      .where((l) => l.bookId == bookId && l.status == LoanStatus.active)
      .firstOrNull;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    // Обе роли запрашиваются параллельно: ждём ~800 мс, а не 1600.
    final [lent, borrowed] = await Future.wait([
      _repository.fetchAll(role: LoanRole.lent),
      _repository.fetchAll(role: LoanRole.borrowed),
    ]);
    switch ((lent, borrowed)) {
      case (Ok(value: final l), Ok(value: final b)):
        _lent = l;
        _borrowed = b;
      case (Err(:final msg), _) || (_, Err(:final msg)):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }

  /// «Запросить книгу»: создаёт запись Loan; книга становится «выдана».
  Future<String?> request(Book book, DateTime dueDate) async {
    switch (await _repository.create(
      Loan.request(bookId: book.id, dueDate: dueDate),
    )) {
      case Ok(:final value):
        _borrowed = [value, ..._borrowed];
        notifyListeners(); // бейдж вкладки «Обмены» растёт сам
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  /// Владелец отмечает возврат: обмен закрыт, книга снова доступна.
  Future<String?> markReturned(Loan loan) async {
    switch (await _repository.update(
      loan.copyWith(status: LoanStatus.returned),
    )) {
      case Ok(:final value):
        _lent = [for (final l in _lent) l.id == value.id ? value : l];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }
}
