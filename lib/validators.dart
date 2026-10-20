// Валидаторы форм. Идиома validator-а: null — значение ВАЛИДНО,
// строка — текст ошибки, который Flutter сам рисует красным под полем.

/// E-mail: непустой и правдоподобного формата «имя@домен.зона».
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Введите e-mail';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Неверный формат e-mail';
  }
  return null;
}

/// Минимальная длина пароля.
const minPasswordLength = 6;

/// Пароль: не короче [minPasswordLength] символов.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Введите пароль';
  if (value.length < minPasswordLength) {
    return 'Минимум $minPasswordLength символов';
  }
  return null;
}

/// Название книги: обязательно (по ТЗ темы).
String? validateBookTitle(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Введите название книги' : null;

/// Автор: обязателен (по ТЗ темы), не короче двух символов и с буквами.
String? validateAuthor(String? value) {
  final author = value?.trim() ?? '';
  if (author.isEmpty) return 'Введите автора';
  if (author.length < 2) return 'Имя автора слишком короткое';
  if (!RegExp(r'\p{L}', unicode: true).hasMatch(author)) {
    return 'Имя автора должно содержать буквы';
  }
  return null;
}

/// Жанр: нужно выбрать из списка.
String? validateGenre(String? value) => value == null ? 'Выберите жанр' : null;

/// Максимальный срок обмена: книга не должна «зависать» у заёмщика.
const maxLoanDays = 60;

/// Срок возврата: выбран, строго в будущем и не дальше [maxLoanDays] дней.
/// [now] передаётся в тестах; в приложении — текущая дата.
String? validateDueDate(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Выберите срок возврата';
  final today = _dateOnly(now ?? DateTime.now());
  final due = _dateOnly(date);
  if (!due.isAfter(today)) return 'Срок возврата должен быть в будущем';
  if (due.difference(today).inDays > maxLoanDays) {
    return 'Не дольше $maxLoanDays дней';
  }
  return null;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
