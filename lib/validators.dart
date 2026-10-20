// Валидаторы форм. Идиома validator-а: null — значение ВАЛИДНО,
// строка — текст ошибки, который Flutter сам рисует красным под полем.

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
