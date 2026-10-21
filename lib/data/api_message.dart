import 'dart:convert';

import 'package:http/http.dart' as http;

/// Переводит конверт ошибки сервера {"error": {"code", "message"}} в сообщение
/// для человека. code стабилен и принадлежит программе; английский message
/// на экран не попадает — русский текст решается здесь, в одном месте.
String apiMessage(http.Response res) {
  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final error = body['error'] as Map<String, dynamic>;
    final message = error['message'] as String? ?? '';
    return switch (error['code'] as String?) {
      'VALIDATION_ERROR' => _validation(message),
      'UNAUTHORIZED' => 'Неверный email или пароль',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      final code => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    return 'Ошибка сервера (${res.statusCode})'; // тело не JSON: HTML прокси и т. п.
  } on TypeError {
    return 'Ошибка сервера (${res.statusCode})'; // JSON, но не наш конверт
  }
}

/// Сервер объясняет отказ валидации по-английски; известные случаи темы
/// переводим, остальное — общей фразой.
String _validation(String message) => switch (message) {
  _ when message.contains('already lent') =>
    'Книгу уже выдали — выберите другую',
  _ when message.contains('own book') => 'Свою книгу запросить нельзя',
  _ when message.contains('in the future') =>
    'Срок возврата должен быть в будущем',
  _ when message.contains('longer than') => 'Срок обмена слишком длинный',
  _ when message.contains('mark it returned') =>
    'Книга выдана — сначала отметьте возврат',
  _ when message.contains('too large') => 'Файл больше 5 МБ',
  _ => 'Отправленные данные недействительны',
};
