import 'package:flutter_test/flutter_test.dart';

import 'package:booknest/data/loan.dart';
import 'package:booknest/data/loan_repository.dart';
import 'package:booknest/data/result.dart';
import 'package:booknest/models/loans_model.dart';
import 'package:booknest/models/offline_status.dart';
import 'package:booknest/models/session_model.dart';

import '../support/fakes.dart';

void main() {
  group('LoansModel', () {
    late FakeLoanRepository repo;
    late LoansModel model;

    setUp(() {
      repo = FakeLoanRepository(
        lent: [
          loan(1, bookId: 10),
          loan(2, bookId: 11, status: LoanStatus.returned),
        ],
        borrowed: [loan(3, bookId: 20)],
      );
      model = LoansModel(repo);
    });

    test('load: обе роли; бейдж считает только активные', () async {
      await model.load();
      expect([for (final l in model.lent) l.id], [1, 2]);
      expect([for (final l in model.borrowed) l.id], [3]);
      expect(model.activeCount, 2);
      expect(model.activeLoanFor(10)?.id, 1);
      expect(model.activeLoanFor(11), isNull); // возвращённый — не «у кого-то»
    });

    test(
      'упала одна из ролей — экран показывает ошибку, а не полсписка',
      () async {
        repo.listErrors[LoanRole.borrowed] = const Err('Сервер не отвечает');
        await model.load();
        expect(model.error, 'Сервер не отвечает');
        expect(model.isLoading, isFalse);
      },
    );

    test(
      'request: новый обмен в «Взятых», бейдж растёт, подписчик извещён',
      () async {
        await model.load();
        var notified = 0;
        model.addListener(() => notified++);

        final error = await model.request(book(30), DateTime(2026, 11, 20));
        expect(error, isNull);
        expect(model.borrowed.first.bookId, 30);
        expect(model.borrowed.first.dueDate, DateTime(2026, 11, 20));
        expect(model.activeCount, 3);
        expect(notified, 1);
      },
    );

    test('request с отказом сервера — сообщение, список прежний', () async {
      await model.load();
      repo.writeError = const Err('Книгу уже выдали — выберите другую');
      expect(
        await model.request(book(30), DateTime(2026, 11, 20)),
        'Книгу уже выдали — выберите другую',
      );
      expect(model.borrowed.length, 1);
    });

    test('markReturned: обмен закрыт, бейдж уменьшился', () async {
      await model.load();
      expect(await model.markReturned(model.lent.first), isNull);
      expect(model.lent.first.status, LoanStatus.returned);
      expect(model.activeCount, 1);
    });
  });

  group('SessionModel', () {
    test('вход и выход извещают подписчиков', () {
      final session = SessionModel();
      final log = <bool>[];
      session.addListener(() => log.add(session.isSignedIn));

      session.signIn(email: 'vitalii@booknest.md', name: 'Vitalii');
      expect(session.name, 'Vitalii');
      session.signOut();
      expect(session.email, isNull);
      expect(log, [true, false]);
    });
  });

  group('OfflineStatus', () {
    test('извещает только при смене источника', () {
      final status = OfflineStatus();
      var notified = 0;
      status.addListener(() => notified++);
      final at = DateTime(2026, 10, 21, 10, 41);

      status.report(null); // уже «онлайн» — без перестройки
      expect(notified, 0);
      status.report(at);
      status.report(at); // тот же снимок — снова без перестройки
      expect(status.isOffline, isTrue);
      expect(status.cachedAt, at);
      status.report(null);
      expect(status.isOffline, isFalse);
      expect(notified, 2);
    });
  });
}
