import 'cached_book_repository.dart';
import 'loan.dart';
import 'loan_repository.dart';
import 'offline_cache.dart';
import 'result.dart';

/// Декоратор (L6) для обменов — тот же приём, что CachedBookRepository:
/// «Мои обмены» и сроки возврата видны и без связи с сервером.
class CachedLoanRepository implements LoanRepository {
  CachedLoanRepository(this._remote, this._cache, {this.onSource});

  final LoanRepository _remote;
  final OfflineCache _cache;
  final SourceListener? onSource;

  @override
  Future<Result<List<Loan>>> fetchAll({required LoanRole role}) async {
    final key = 'loans:${role.name}';
    final result = await _remote.fetchAll(role: role);
    switch (result) {
      case Ok(:final value):
        onSource?.call(null);
        await _cache.putList(key, [for (final l in value) l.toStorageJson()]);
        return result;
      case Err(isNetwork: true):
        final cached = await _cache.getList(key, Loan.fromJson);
        if (cached == null) return result;
        onSource?.call(cached.savedAt);
        return Ok(cached.items);
      case Err():
        return result;
    }
  }

  @override
  Future<Result<Loan>> fetchById(int id) => _remote.fetchById(id);

  @override
  Future<Result<Loan>> create(Loan draft) => _remote.create(draft);

  @override
  Future<Result<Loan>> update(Loan loan) => _remote.update(loan);

  @override
  Future<Result<void>> delete(int id) => _remote.delete(id);
}
