import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:booknest/data/result.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> chooseGenre(WidgetTester tester, String genre) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(genre).last); // .last — пункт открытого меню
  await tester.pumpAndSettle();
}

void main() {
  /// Библиотека → FAB «Добавить книгу» → форма.
  Future<TestApp> openNewBookForm(WidgetTester tester) async {
    final app = TestApp(mine: [book(1)]);
    await app.start(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить книгу'));
    await tester.pumpAndSettle();
    expect(find.text('Новая книга'), findsOneWidget);
    return app;
  }

  testWidgets('пустой submit: три ошибки, хранилище не тронуто', (
    tester,
  ) async {
    final app = await openNewBookForm(tester);
    await tester.tap(find.text('Сохранить'));
    await tester.pump();

    expect(find.text('Введите название книги'), findsOneWidget);
    expect(find.text('Введите автора'), findsOneWidget);
    expect(find.text('Выберите жанр'), findsOneWidget);
    expect(app.library.books.length, 1);
  });

  testWidgets('в имя автора цифры не вводятся', (tester) async {
    await openNewBookForm(tester);
    await tester.enterText(field('Автор *'), 'Оруэлл 1984');
    expect(find.text('Оруэлл '), findsOneWidget);
  });

  testWidgets('добавление: «Сохранить» → назад, новая книга уже в списке', (
    tester,
  ) async {
    final app = await openNewBookForm(tester);
    await tester.enterText(field('Название *'), 'Дюна');
    await tester.enterText(field('Автор *'), 'Фрэнк Герберт');
    await chooseGenre(tester, 'Фантастика');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(app.router.state.uri.path, '/books'); // форма закрылась
    expect(find.text('Книга «Дюна» добавлена'), findsOneWidget);
    expect(find.text('Дюна'), findsOneWidget); // список обновился сам
    expect(app.library.books.first.genre, 'Фантастика');
  });

  testWidgets('отказ хранилища: SnackBar, форма открыта, ввод не потерян', (
    tester,
  ) async {
    final app = await openNewBookForm(tester);
    app.library.writeError = const Err('Нет сети — повторите попытку');
    await tester.enterText(field('Название *'), 'Дюна');
    await tester.enterText(field('Автор *'), 'Фрэнк Герберт');
    await chooseGenre(tester, 'Фантастика');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Нет сети — повторите попытку'), findsOneWidget);
    expect(find.text('Новая книга'), findsOneWidget);
    expect(find.text('Фрэнк Герберт'), findsOneWidget);
  });

  testWidgets(
    'редактирование: карточка → форма с данными → изменения в карточке',
    (tester) async {
      final app = TestApp(
        mine: [book(1, title: '1984', genre: 'Антиутопия')],
      );
      await app.start(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('1984'));
      await tester.pumpAndSettle();
      expect(find.text('Карточка книги'), findsOneWidget);
      await tester.tap(find.text('Редактировать'));
      await tester.pumpAndSettle();

      expect(find.text('Редактирование'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '1984'), findsOneWidget);
      expect(find.text('Антиутопия'), findsOneWidget); // жанр выбран заранее

      await tester.enterText(field('1984'), '1984 (новый перевод)');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(app.router.state.uri.path, '/books/1');
      expect(find.text('1984 (новый перевод)'), findsOneWidget);
    },
  );
}
