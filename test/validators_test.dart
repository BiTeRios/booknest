import 'package:flutter_test/flutter_test.dart';

import 'package:booknest/validators.dart';

// Идиома validator-а: null — значение валидно, строка — текст ошибки.
void main() {
  group('validateEmail', () {
    test('пустое и из пробелов — «Введите e-mail»', () {
      expect(validateEmail(null), 'Введите e-mail');
      expect(validateEmail('   '), 'Введите e-mail');
    });

    test('без @, без зоны, с пробелом — неверный формат', () {
      for (final bad in ['vitalii', 'vitalii@booknest', 'a b@c.md', '@c.md']) {
        expect(validateEmail(bad), 'Неверный формат e-mail', reason: bad);
      }
    });

    test('правдоподобный адрес валиден, пробелы по краям не мешают', () {
      expect(validateEmail('vitalii@booknest.md'), isNull);
      expect(validateEmail('  vitalii@booknest.md  '), isNull);
    });
  });

  group('validatePassword', () {
    test('пустой — «Введите пароль»', () {
      expect(validatePassword(''), 'Введите пароль');
      expect(validatePassword(null), 'Введите пароль');
    });

    test('граница длины: 5 символов — ошибка, 6 — норма', () {
      expect(validatePassword('12345'), 'Минимум $minPasswordLength символов');
      expect(validatePassword('123456'), isNull);
    });
  });

  group('validateName', () {
    test('пустое, одна буква, норма', () {
      expect(validateName(' '), 'Введите имя');
      expect(validateName('V'), 'Имя слишком короткое');
      expect(validateName('Vitalii'), isNull);
    });
  });

  group('книга', () {
    test('название обязательно', () {
      expect(validateBookTitle(''), 'Введите название книги');
      expect(validateBookTitle('   '), 'Введите название книги');
      expect(validateBookTitle('1984'), isNull); // цифры в названии — норма
    });

    test('автор: обязателен, ≥ 2 символов, с буквами (в т. ч. кириллица)', () {
      expect(validateAuthor(''), 'Введите автора');
      expect(validateAuthor('Б'), 'Имя автора слишком короткое');
      expect(validateAuthor('--'), 'Имя автора должно содержать буквы');
      expect(validateAuthor('Михаил Булгаков'), isNull);
      expect(validateAuthor('Liviu Rebreanu'), isNull);
    });

    test('жанр выбирается из списка', () {
      expect(validateGenre(null), 'Выберите жанр');
      expect(validateGenre('Классика'), isNull);
    });
  });

  group('validateDueDate — «сегодня» подставляет тест', () {
    final now = DateTime(2026, 10, 21, 15, 30); // середина дня

    test('не выбран', () {
      expect(validateDueDate(null, now: now), 'Выберите срок возврата');
    });

    test('сегодня и вчера — не будущее', () {
      expect(
        validateDueDate(DateTime(2026, 10, 21), now: now),
        'Срок возврата должен быть в будущем',
      );
      expect(
        validateDueDate(DateTime(2026, 10, 20), now: now),
        'Срок возврата должен быть в будущем',
      );
    });

    test('завтра — норма, хотя до него меньше 24 часов', () {
      expect(validateDueDate(DateTime(2026, 10, 22, 9), now: now), isNull);
    });

    // Дни считаем по календарю: DateTime(…, 21 + 60) — это 20 декабря.
    // add(Duration(days: 60)) прибавил бы 60×24 ч и через перевод часов
    // 25 октября попал бы на 19.12 23:00 — ошибка уже в самом тесте.
    test(
      'граница $maxLoanDays дней: ровно — норма, на день больше — ошибка',
      () {
        expect(
          validateDueDate(DateTime(2026, 10, 21 + maxLoanDays), now: now),
          isNull,
        );
        expect(
          validateDueDate(DateTime(2026, 10, 21 + maxLoanDays + 1), now: now),
          'Не дольше $maxLoanDays дней',
        );
      },
    );

    test('весенний перевод часов не дарит лишний день', () {
      // 28.03.2027 в Кишинёве сутки длятся 23 ч: разница местных полуночей
      // 1.03 → 1.05 — 60 дней 23 часа, и inDays дал бы 60 вместо 61.
      final march = DateTime(2027, 3, 1, 12);
      expect(
        validateDueDate(DateTime(2027, 3, 1 + maxLoanDays), now: march),
        isNull,
      );
      expect(
        validateDueDate(DateTime(2027, 3, 1 + maxLoanDays + 1), now: march),
        'Не дольше $maxLoanDays дней',
      );
    });
  });
}
