import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:booknest/widgets/book_card.dart';
import 'package:booknest/widgets/error_view.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  testWidgets('три состояния: spinner → список', (tester) async {
    final app = TestApp(mine: [book(1), book(2), book(3)]);
    app.library.gate = Completer();

    await app.start(tester);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(BookCard), findsNothing);

    app.library.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(BookCard), findsNWidgets(3));
    expect(find.text('Книга 2'), findsOneWidget);
  });

  testWidgets('ошибка никогда не молчит: ErrorView → «Повторить» → данные', (
    tester,
  ) async {
    final app = TestApp(mine: [book(1)]);
    app.library.listError = networkDown;

    await app.start(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Нет сети — повторите попытку'), findsOneWidget);

    app.library.listError = null; // сеть вернулась
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Книга 1'), findsOneWidget);
  });

  testWidgets('пустой результат — «Ничего не найдено»', (tester) async {
    await TestApp().start(tester);
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('поиск по Enter и чип жанра уходят в хранилище', (tester) async {
    final app = TestApp(
      mine: [
        book(1, title: 'Мастер и Маргарита'),
        book(2, title: 'Дюна', genre: 'Фантастика'),
      ],
    );
    await app.start(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), '  дюна ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(app.library.fetches.last.search, 'дюна'); // пробелы обрезаны
    expect(find.text('Дюна'), findsOneWidget);
    expect(find.text('Мастер и Маргарита'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Классика'));
    await tester.pumpAndSettle();
    expect(app.library.fetches.last.genre, 'Классика');
  });

  testWidgets('пагинация: долистал до хвоста — пришла следующая страница', (
    tester,
  ) async {
    final app = TestApp(mine: [for (var i = 1; i <= 15; i++) book(i)]);
    await app.start(tester);
    await tester.pumpAndSettle();
    expect(find.text('Книга 15'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Книга 15'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect([for (final f in app.library.fetches) f.page], [1, 2]);
    expect(find.text('Книга 15'), findsOneWidget);
  });

  testWidgets('свайп: удаление только после подтверждения', (tester) async {
    final app = TestApp(mine: [book(1), book(2)]);
    await app.start(tester);
    await tester.pumpAndSettle();

    // Отмена — карточка возвращается, хранилище не тронуто.
    await tester.drag(find.byKey(const ValueKey(1)), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Удалить книгу?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Книга 1'), findsOneWidget);
    expect(app.library.books.length, 2);

    // Подтверждение — книга удалена в хранилище и исчезла с экрана.
    await tester.drag(find.byKey(const ValueKey(1)), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Удалить'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Книга 1'), findsNothing);
    expect(find.text('Книга «Книга 1» удалена'), findsOneWidget);
    expect([for (final b in app.library.books) b.id], [2]);
  });
}
