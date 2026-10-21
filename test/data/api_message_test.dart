import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:booknest/data/api_message.dart';

/// Ответ с конвертом ошибки {"error": {"code", "message"}}.
http.Response envelope(int status, String code, [String message = '']) =>
    http.Response(
      jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      status,
    );

void main() {
  test('стабильные коды сервера → русский текст', () {
    expect(
      apiMessage(envelope(401, 'UNAUTHORIZED')),
      'Неверный email или пароль',
    );
    expect(
      apiMessage(envelope(409, 'EMAIL_TAKEN')),
      'Аккаунт с этим email уже существует',
    );
    expect(apiMessage(envelope(404, 'NOT_FOUND')), 'Запись не существует');
  });

  test('неизвестный код не теряется — он виден в сообщении', () {
    expect(apiMessage(envelope(500, 'INTERNAL')), 'Ошибка сервера (INTERNAL)');
  });

  test('VALIDATION_ERROR: известные случаи темы переводятся', () {
    // Слева — дословные тексты server/lib (books.dart, loans.dart, files).
    final cases = {
      'The book is already lent': 'Книгу уже выдали — выберите другую',
      'You cannot borrow your own book': 'Свою книгу запросить нельзя',
      'dueDate must be in the future': 'Срок возврата должен быть в будущем',
      'A loan cannot be longer than 60 days': 'Срок обмена слишком длинный',
      'The book is lent: mark it returned first':
          'Книга выдана — сначала отметьте возврат',
      'File too large: the upload limit is 5 MB': 'Файл больше 5 МБ',
      'title is required': 'Отправленные данные недействительны',
    };
    cases.forEach((server, expected) {
      expect(
        apiMessage(envelope(400, 'VALIDATION_ERROR', server)),
        expected,
        reason: server,
      );
    });
  });

  test('тело не JSON (HTML прокси) — общая фраза со статусом', () {
    expect(
      apiMessage(http.Response('<html>Bad Gateway</html>', 502)),
      'Ошибка сервера (502)',
    );
  });

  test('JSON, но не наш конверт — тоже общая фраза', () {
    expect(
      apiMessage(http.Response('{"detail": "oops"}', 500)),
      'Ошибка сервера (500)',
    );
    expect(apiMessage(http.Response('[1, 2]', 500)), 'Ошибка сервера (500)');
  });
}
