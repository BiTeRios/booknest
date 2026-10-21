// Demo data for BookNest: five users, 32 books, 12 loans — enough for the
// community list, both loan tabs and pagination (more than 20 books).
// Loan dates are relative to today, so «overdue» and «N days left» always
// look right. Safe to run twice: does nothing if the demo users exist.
//
// Run (from server/, server may be stopped or running):  dart run tool/seed.dart
// All demo users have the password «parola123».

import 'package:server/auth.dart';
import 'package:server/db.dart';

const password = 'parola123';

const users = {
  'vitalii': ('vitalii@booknest.md', 'Vitalii Liogchi'),
  'ana': ('ana.rusu@booknest.md', 'Ana Rusu'),
  'ion': ('ion.popescu@booknest.md', 'Ion Popescu'),
  'maria': ('maria.ceban@booknest.md', 'Maria Ceban'),
  'dan': ('dan.turcanu@booknest.md', 'Dan Țurcanu'),
};

/// (owner, title, author, genre)
const books = [
  ('vitalii', 'Мастер и Маргарита', 'Михаил Булгаков', 'Классика'),
  ('vitalii', '1984', 'Джордж Оруэлл', 'Антиутопия'),
  ('vitalii', 'Ion', 'Liviu Rebreanu', 'Классика'),
  (
    'vitalii',
    'Чистый код. Создание, анализ и рефакторинг',
    'Роберт Мартин',
    'IT'
  ),
  ('vitalii', 'Дюна', 'Фрэнк Герберт', 'Фантастика'),
  (
    'vitalii',
    'Sapiens. Краткая история человечества',
    'Юваль Ной Харари',
    'Нон-фикшн'
  ),
  ('vitalii', 'Убийство в «Восточном экспрессе»', 'Агата Кристи', 'Детектив'),
  ('vitalii', 'Гарри Поттер и философский камень', 'Джоан Роулинг', 'Фэнтези'),
  ('ana', 'Преступление и наказание', 'Фёдор Достоевский', 'Классика'),
  ('ana', 'Думай медленно… решай быстро', 'Даниэль Канеман', 'Нон-фикшн'),
  ('ana', 'Гордость и предубеждение', 'Джейн Остин', 'Классика'),
  ('ana', 'Код да Винчи', 'Дэн Браун', 'Детектив'),
  ('ana', 'Девушка с татуировкой дракона', 'Стиг Ларссон', 'Детектив'),
  ('ana', 'Атомные привычки', 'Джеймс Клир', 'Нон-фикшн'),
  ('ion', 'Автостопом по галактике', 'Дуглас Адамс', 'Фантастика'),
  ('ion', 'О дивный новый мир', 'Олдос Хаксли', 'Антиутопия'),
  ('ion', 'Мы', 'Евгений Замятин', 'Антиутопия'),
  ('ion', 'Солярис', 'Станислав Лем', 'Фантастика'),
  ('ion', 'Программист-прагматик', 'Эндрю Хант, Дэвид Томас', 'IT'),
  ('ion', 'Ведьмак. Последнее желание', 'Анджей Сапковский', 'Фэнтези'),
  ('maria', 'Алгоритмы. Построение и анализ', 'Томас Кормен и др.', 'IT'),
  ('maria', 'Маленький принц', 'Антуан де Сент-Экзюпери', 'Классика'),
  ('maria', 'Гарри Поттер и Тайная комната', 'Джоан Роулинг', 'Фэнтези'),
  ('maria', 'Грокаем алгоритмы', 'Адитья Бхаргава', 'IT'),
  ('maria', 'Сто лет одиночества', 'Габриэль Гарсиа Маркес', 'Классика'),
  ('maria', 'Шантарам', 'Грегори Дэвид Робертс', 'Классика'),
  ('dan', 'Властелин колец. Братство Кольца', 'Джон Р. Р. Толкин', 'Фэнтези'),
  ('dan', 'Шерлок Холмс. Собака Баскервилей', 'Артур Конан Дойл', 'Детектив'),
  ('dan', 'Убить пересмешника', 'Харпер Ли', 'Классика'),
  ('dan', '451° по Фаренгейту', 'Рэй Брэдбери', 'Антиутопия'),
  ('dan', 'Задача трёх тел', 'Лю Цысинь', 'Фантастика'),
  ('dan', 'Краткая история времени', 'Стивен Хокинг', 'Нон-фикшн'),
];

/// (book title, borrower, start: days from today, due: days from today, active)
const loans = [
  ('1984', 'ana', -20, 8, true),
  ('Дюна', 'ion', -11, 17, true),
  ('Гарри Поттер и философский камень', 'maria', -7, 14, true),
  ('Мастер и Маргарита', 'maria', -50, -29, false),
  ('Чистый код. Создание, анализ и рефакторинг', 'dan', -66, -49, false),
  ('Sapiens. Краткая история человечества', 'ion', -46, -25, false),
  ('Алгоритмы. Построение и анализ', 'vitalii', -16, 12, true),
  ('Думай медленно… решай быстро', 'vitalii', -23, -2, true), // просрочен
  ('Шерлок Холмс. Собака Баскервилей', 'vitalii', -9, 5, true),
  ('Маленький принц', 'vitalii', -41, -27, false),
  ('Автостопом по галактике', 'vitalii', -61, -45, false),
  ('О дивный новый мир', 'vitalii', -110, -90, false),
];

void main() {
  initDb('app.db');
  final exists = db.select(
    'SELECT id FROM users WHERE email = ?',
    [users['vitalii']!.$1],
  );
  if (exists.isNotEmpty) {
    print('Демо-данные уже есть — ничего не делаю.');
    return;
  }

  final today = DateTime.now();
  String day(int offset) =>
      isoDate(DateTime(today.year, today.month, today.day + offset));

  transaction(() {
    final userIds = <String, int>{};
    for (final MapEntry(:key, value: (email, name)) in users.entries) {
      db.execute(
        'INSERT INTO users (email, password_hash, name, created_at) '
        'VALUES (?, ?, ?, ?)',
        [email, hashPassword(password), name, nowIso()],
      );
      userIds[key] = db.lastInsertRowId;
    }

    final lentTitles = {
      for (final l in loans)
        if (l.$5) l.$1
    };
    final bookIds = <String, int>{};
    // The API lists newest first, so insert in reverse: the first book above
    // ends up first in the app.
    for (final (owner, title, author, genre) in books.reversed) {
      db.execute(
        'INSERT INTO books (user_id, title, author, genre, status, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          userIds[owner],
          title,
          author,
          genre,
          lentTitles.contains(title) ? 'lent' : 'available',
          nowIso(),
        ],
      );
      bookIds[title] = db.lastInsertRowId;
    }

    for (final (title, borrower, start, due, active) in loans.reversed) {
      db.execute(
        'INSERT INTO loans (book_id, borrower_id, start_date, due_date, status, '
        'created_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          bookIds[title],
          userIds[borrower],
          day(start),
          day(due),
          active ? 'active' : 'returned',
          nowIso(),
        ],
      );
    }
  });

  print('Готово: ${users.length} пользователей, ${books.length} книг, '
      '${loans.length} обменов. Пароль у всех: $password');
  print('Вход в приложение: ${users['vitalii']!.$1} / $password');
}
