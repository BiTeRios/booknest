/// Дата в формате 29.10.2026 (без пакета intl).
String formatDate(DateTime date) =>
    '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';

/// Время в формате 09:05.
String formatTime(DateTime date) =>
    '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

String _twoDigits(int n) => n.toString().padLeft(2, '0');
