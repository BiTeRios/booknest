import 'loan.dart';
import 'result.dart';

/// Роль текущего пользователя в обмене: выдал книгу или взял её.
enum LoanRole { lent, borrowed }

/// Контракт хранилища обменов — вторая пишущая сущность темы, тот же шаблон:
///   fetchAll  → GET    /loans?role=…
///   fetchById → GET    /loans/{id}
///   create    → POST   /loans {bookId, dueDate}  (книга становится «выдана»)
///   update    → PUT    /loans/{id}               (возврат: status = returned)
///   delete    → DELETE /loans/{id}
abstract class LoanRepository {
  Future<Result<List<Loan>>> fetchAll({required LoanRole role});
  Future<Result<Loan>> fetchById(int id);
  Future<Result<Loan>> create(Loan draft);
  Future<Result<Loan>> update(Loan loan);
  Future<Result<void>> delete(int id);
}
