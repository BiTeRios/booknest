// SQLite setup. The database file is created automatically on first start.
//
// To add your own entity: add a CREATE TABLE below, then copy the pattern
// of lib/notes.dart for its routes.

import 'package:sqlite3/sqlite3.dart';

/// The single database connection, opened once at startup by [initDb].
late final Database db;

/// Opens (and creates, on first run) the database and its schema.
void initDb(String path) {
  db = sqlite3.open(path);
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      email         TEXT    NOT NULL UNIQUE,
      password_hash TEXT    NOT NULL,
      name          TEXT    NOT NULL,
      created_at    TEXT    NOT NULL
    );

    CREATE TABLE IF NOT EXISTS notes (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    INTEGER NOT NULL REFERENCES users (id),
      title      TEXT    NOT NULL,
      content    TEXT    NOT NULL DEFAULT '',
      created_at TEXT    NOT NULL
    );

    CREATE TABLE IF NOT EXISTS files (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    INTEGER NOT NULL REFERENCES users (id),
      name       TEXT    NOT NULL,
      mime_type  TEXT    NOT NULL,
      size       INTEGER NOT NULL,
      path       TEXT    NOT NULL,
      created_at TEXT    NOT NULL
    );

    -- BookNest: a book in its owner's personal library.
    -- status is managed by the loans module, never by PUT /books.
    CREATE TABLE IF NOT EXISTS books (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    INTEGER NOT NULL REFERENCES users (id),
      title      TEXT    NOT NULL,
      author     TEXT    NOT NULL,
      genre      TEXT    NOT NULL DEFAULT '',
      cover_url  TEXT,
      status     TEXT    NOT NULL DEFAULT 'available'
                 CHECK (status IN ('available', 'lent')),
      created_at TEXT    NOT NULL
    );

    -- BookNest: a book lent by its owner to another user until due_date.
    -- Dates are plain calendar dates, 'YYYY-MM-DD'.
    CREATE TABLE IF NOT EXISTS loans (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id     INTEGER NOT NULL REFERENCES books (id),
      borrower_id INTEGER NOT NULL REFERENCES users (id),
      start_date  TEXT    NOT NULL,
      due_date    TEXT    NOT NULL,
      status      TEXT    NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'returned')),
      created_at  TEXT    NOT NULL
    );
  ''');

  // SQLite's lower() and LIKE only fold ASCII letters, so a search for
  // «мастер» would miss «Мастер». ulower() lowercases with Dart instead.
  db.createFunction(
    functionName: 'ulower',
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    function: (args) => (args[0] as String?)?.toLowerCase(),
  );
}

/// Current UTC time in ISO-8601, the format used for all timestamps.
String nowIso() => DateTime.now().toUtc().toIso8601String();

/// A calendar date as 'YYYY-MM-DD' (the format of loan dates).
String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Runs [body] in a transaction: all its statements apply, or none do.
T transaction<T>(T Function() body) {
  db.execute('BEGIN');
  try {
    final result = body();
    db.execute('COMMIT');
    return result;
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
