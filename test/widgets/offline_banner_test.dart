import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('баннер «нет связи» виден только с данными из кэша', (
    tester,
  ) async {
    final app = TestApp(mine: [book(1)]);
    await app.start(tester);
    await tester.pumpAndSettle();
    const text = 'Нет связи с сервером. Показаны данные от 21.10.2026 10:41';
    expect(find.text(text), findsNothing); // онлайн — баннера нет

    app.offline.report(DateTime(2026, 10, 21, 10, 41)); // кэш-снимок
    await tester.pumpAndSettle();
    expect(find.text(text), findsOneWidget);

    // Баннер — часть оболочки: виден на любой вкладке.
    await tester.tap(find.text('Обмены'));
    await tester.pumpAndSettle();
    expect(find.text(text), findsOneWidget);

    app.offline.report(null); // сервер снова ответил
    await tester.pumpAndSettle();
    expect(find.text(text), findsNothing);
  });
}
