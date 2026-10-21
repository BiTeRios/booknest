import 'api_client.dart';
import 'loan.dart';
import 'loan_repository.dart';
import 'result.dart';

/// Вторая реализация интерфейса L4 — обмены на backend-е.
/// Статус книги при создании и возврате обмена меняет сервер, в одной транзакции.
class HttpLoanRepository implements LoanRepository {
  HttpLoanRepository(this._api);

  final ApiClient _api;

  static Loan _loan(Object? json) =>
      Loan.fromJson(json as Map<String, dynamic>);

  @override
  Future<Result<List<Loan>>> fetchAll({required LoanRole role}) => _api.send(
    'GET',
    '/loans',
    query: {'role': role.name},
    okStatus: 200,
    parse: (json) => ApiClient.items(json, Loan.fromJson),
  );

  @override
  Future<Result<Loan>> fetchById(int id) =>
      _api.send('GET', '/loans/$id', okStatus: 200, parse: _loan);

  @override
  Future<Result<Loan>> create(Loan draft) => _api.send(
    'POST',
    '/loans',
    body: draft.toJson(), // сервер берёт bookId и dueDate
    okStatus: 201,
    parse: _loan,
  );

  @override
  Future<Result<Loan>> update(Loan loan) => _api.send(
    'PUT',
    '/loans/${loan.id}',
    body: loan.toJson(), // сервер берёт status (возврат)
    okStatus: 200,
    parse: _loan,
  );

  @override
  Future<Result<void>> delete(int id) =>
      _api.send('DELETE', '/loans/$id', okStatus: 204, parse: (_) {});
}
