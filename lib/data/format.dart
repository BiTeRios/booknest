/// Дата в формате 29.10.2026 (без пакета intl).
String formatDate(DateTime date) =>
    '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';

String _twoDigits(int n) => n.toString().padLeft(2, '0');
