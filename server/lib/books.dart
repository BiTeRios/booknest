// Books: BookNest's main entity, built from the notes.dart template.
//
// Two deliberate differences from notes:
//  * BookNest exists to show your books to others, so a user lists either
//    their own library (?scope=mine) or everyone else's (?scope=community),
//    and GET /books/{id} works for any book. Changing or deleting a book is
//    owner-only: someone else's book answers 404, as in notes.
//  * status (available / lent) belongs to the loans module: POST creates a
//    book as available, PUT never touches status.

import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'auth.dart';
import 'db.dart';
import 'errors.dart';

/// Books with their owner's name (the community list shows who has the book).
const _select = '''
  SELECT b.*, u.name AS owner_name
  FROM books b JOIN users u ON u.id = b.user_id''';

Map<String, Object?> _toJson(Row row) => {
      'id': row['id'],
      'ownerId': row['user_id'],
      'ownerName': row['owner_name'],
      'title': row['title'],
      'author': row['author'],
      'genre': row['genre'],
      'coverUrl': row['cover_url'],
      'status': row['status'],
      'createdAt': row['created_at'],
    };

/// Finds any book by id (books are visible to everyone).
Row? _find(String? idParam) {
  final id = int.tryParse(idParam ?? '');
  if (id == null) return null;
  final rows = db.select('$_select WHERE b.id = ?', [id]);
  return rows.isEmpty ? null : rows.first;
}

/// Finds a book only among the current user's own books.
Row? _findOwn(Request request) {
  final row = _find(request.params['id']);
  if (row == null || row['user_id'] != currentUserId(request)) return null;
  return row;
}

/// The optional coverUrl field: a string (e.g. "/files/7"), or null to clear.
String? _coverUrl(Map<String, dynamic> body) =>
    body['coverUrl'] is String ? stringField(body, 'coverUrl') : null;

/// GET /books?scope=mine|community&page=1&limit=20&search=&genre=
///   -> {items, page, limit, total}
Future<Response> listBooks(Request request) async {
  final query = request.url.queryParameters;
  final page = max(int.tryParse(query['page'] ?? '') ?? 1, 1);
  final limit = (int.tryParse(query['limit'] ?? '') ?? 20).clamp(1, 100);
  final search = (query['search'] ?? '').toLowerCase();
  final genre = query['genre'] ?? '';
  final scope = query['scope'] ?? 'mine';
  if (scope != 'mine' && scope != 'community') {
    return validationError('scope must be "mine" or "community"');
  }

  final where = StringBuffer(
    scope == 'mine' ? 'b.user_id = ?' : 'b.user_id <> ?',
  )..write(' AND (ulower(b.title) LIKE ? OR ulower(b.author) LIKE ?)');
  final args = <Object>[currentUserId(request), '%$search%', '%$search%'];
  if (genre.isNotEmpty) {
    where.write(' AND b.genre = ?');
    args.add(genre);
  }

  final total = db
      .select('SELECT COUNT(*) AS n FROM books b WHERE $where', args)
      .first['n'] as int;
  final rows = db.select(
    '$_select WHERE $where ORDER BY b.id DESC LIMIT ? OFFSET ?',
    [...args, limit, (page - 1) * limit],
  );

  return jsonResponse({
    'items': rows.map(_toJson).toList(),
    'page': page,
    'limit': limit,
    'total': total,
  });
}

/// POST /books  {title, author, genre?, coverUrl?} -> 201 book
Future<Response> createBook(Request request) async {
  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  final title = stringField(body, 'title');
  if (title == null) return validationError('title is required');
  final author = stringField(body, 'author');
  if (author == null) return validationError('author is required');
  final genre = stringField(body, 'genre') ?? '';

  db.execute(
    'INSERT INTO books (user_id, title, author, genre, cover_url, status, '
    'created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [
      currentUserId(request),
      title,
      author,
      genre,
      _coverUrl(body),
      'available',
      nowIso(),
    ],
  );
  final row = _find('${db.lastInsertRowId}')!;
  return jsonResponse(_toJson(row), status: 201);
}

/// GET /books/{id} -> 200 book | 404
Future<Response> getBook(Request request) async {
  final row = _find(request.params['id']);
  if (row == null) return notFound('Book not found');
  return jsonResponse(_toJson(row));
}

/// PUT /books/{id}  {title, author, genre?, coverUrl?} -> 200 book | 404
Future<Response> updateBook(Request request) async {
  final row = _findOwn(request);
  if (row == null) return notFound('Book not found');

  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  final title = stringField(body, 'title');
  if (title == null) return validationError('title is required');
  final author = stringField(body, 'author');
  if (author == null) return validationError('author is required');
  final genre = stringField(body, 'genre') ?? '';

  db.execute(
    'UPDATE books SET title = ?, author = ?, genre = ?, cover_url = ? '
    'WHERE id = ?',
    [title, author, genre, _coverUrl(body), row['id']],
  );
  return jsonResponse(_toJson(_find('${row['id']}')!));
}

/// DELETE /books/{id} -> 204 | 404 | 400 while the book is lent
Future<Response> deleteBook(Request request) async {
  final row = _findOwn(request);
  if (row == null) return notFound('Book not found');
  if (row['status'] == 'lent') {
    return validationError('The book is lent: mark it returned first');
  }

  transaction(() {
    // Its loan history goes with it: a loan without a book means nothing.
    db.execute('DELETE FROM loans WHERE book_id = ?', [row['id']]);
    db.execute('DELETE FROM books WHERE id = ?', [row['id']]);
  });
  return Response(204);
}
