import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:booknest/data/loan.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

/// Число на бейдже вкладки «Обмены» (null — бейдж скрыт).
String? badge(WidgetTester tester) {
  final b = tester.widget<Badge>(find.byType(Badge));
  return b.isLabelVisible ? (b.label as Text).data : null;
}

void main() {
  testWidgets('запрос книги: без срока — ошибка; со сроком — обмен создан', (
    tester,
  ) async {
    final app = TestApp(community: [book(7, title: 'Дюна', ownerId: 2)]);
    await app.start(tester);
    await tester.pumpAndSettle();
    expect(badge(tester), isNull);

    await tester.tap(find.text('Сообщество'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Запросить'));
    await tester.pumpAndSettle();
    expect(find.text('Запрос книги'), findsOneWidget);

    await tester.tap(find.text('Отправить запрос'));
    await tester.pump();
    expect(find.text('Выберите срок возврата'), findsOneWidget);

    // Календарь открывается на «сегодня + 14 дней» — подтверждаем его.
    await tester.tap(find.widgetWithText(TextFormField, 'Вернуть до *'));
    await tester.pumpAndSettle();
    final l10n = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    await tester.tap(find.text(l10n.okButtonLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отправить запрос'));
    await tester.pumpAndSettle();

    expect(app.router.state.uri.path, '/community');
    expect(find.textContaining('Запрос отправлен: «Дюна»'), findsOneWidget);
    expect(
      find.text('Выдана'),
      findsOneWidget,
    ); // книга в списке сменила статус
    expect(badge(tester), '1'); // бейдж вырос сам
  });

  testWidgets('обмены: возврат после подтверждения, бейдж уменьшается', (
    tester,
  ) async {
    final app = TestApp(
      mine: [book(10)],
      lent: [loan(1, bookId: 10)],
      borrowed: [loan(2, bookId: 20)],
    );
    await app.start(tester);
    await tester.pumpAndSettle();
    expect(badge(tester), '2');

    await tester.tap(find.text('Обмены'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отметить возврат'));
    await tester.pumpAndSettle();
    expect(find.text('Книга возвращена?'), findsOneWidget);
    await tester.tap(find.text('Да, вернули'));
    await tester.pumpAndSettle();

    expect(find.text('Отметить возврат'), findsNothing);
    expect(find.text(LoanStatus.returned.label), findsOneWidget);
    expect(badge(tester), '1');
  });

  testWidgets('выход: подтверждение → экран входа, сессия пуста', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'jwt-abc'});
    final app = TestApp();
    app.session.signIn(email: 'vitalii@booknest.md', name: 'Vitalii');
    await app.start(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('vitalii@booknest.md'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Выйти из аккаунта'), 200);
    await tester.tap(find.text('Выйти из аккаунта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Да, выйти'));
    await tester.pumpAndSettle();

    expect(app.router.state.uri.path, '/login');
    expect(app.session.isSignedIn, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
  });
}
