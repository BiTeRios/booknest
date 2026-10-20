import 'package:flutter_test/flutter_test.dart';

import 'package:booknest/main.dart';

void main() {
  testWidgets('Приложение запускается и показывает BookNest', (tester) async {
    await tester.pumpWidget(const BookNestApp());
    expect(find.text('BookNest'), findsWidgets);
  });
}
