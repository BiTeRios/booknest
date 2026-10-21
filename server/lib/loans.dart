// Loans: BookNest's second writing entity — who borrowed which book and
// until when. Built from the notes.dart template.
//
// A loan involves two users, so "mine" means either side: I lent the book
// (I own it) or I borrowed it. Anyone else gets 404, as in notes.
// Creating a loan marks the book lent; returning it makes the book available
// again — both in one transaction, so a book and its loans never disagree.

import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'auth.dart';
import 'db.dart';
import 'errors.dart';

/// Longest allowed loan, in days (the app validates the same limit).
const maxLoanDays = 60;

/// Loans with the book and both participants, ready for display.
const _select = '''
  SELECT l.*, b.title AS book_title, b.author AS book_author,
         b.user_id AS owner_id, o.name AS owner_name,
         br.name AS borrower_name
  FROM loans l
  JOIN books b  ON b.id  = l.book_id
  JOIN users o  ON o.id  = b.user_id
  JOIN users br ON br.id = l.borrower_id''';

Map<String, Object?> _toJson(Row row) => {
      'id': row['id'],
      'bookId': row['book_id'],
      'bookTitle': row['book_title'],
      'bookAuthor': row['book_author'],
      'ownerId': row['owner_id'],
      'ownerName': row['owner_name'],
      'borrowerId': row['borrower_id'],
      'borrowerName': row['borrower_name'],
      'startDate': row['start_date'],
      'dueDate': row['due_date'],
      'status': row['status'],
      'createdAt': row['created_at'],
    };

/// Finds a loan the current user takes part in (as owner or borrower).
Row? _find(int userId, String? idParam) {
  final id = int.tryParse(idParam ?? '');
  if (id == null) return null;
  final rows = db.select(
    '$_select WHERE l.id = ? AND (l.borrower_id = ? OR b.user_id = ?)',
    [id, userId, userId],
  );
  return rows.isEmpty ? null : rows.first;
}

/// Today as a calendar date (time of day dropped).
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// GET /loans?role=lent|borrowed&page=1&limit=20 -> {items, page, limit, total}
/// Without role: every loan the user takes part in.
Future<Response> listLoans(Request request) async {
  final query = request.url.queryParameters;
  final page = max(int.tryParse(query['page'] ?? '') ?? 1, 1);
  final limit = (int.tryParse(query['limit'] ?? '') ?? 20).clamp(1, 100);
  final userId = currentUserId(request);

  final (String where, List<Object> args) = switch (query['role']) {
    'lent' => ('b.user_id = ?', [userId]),
    'borrowed' => ('l.borrower_id = ?', [userId]),
    null || '' => ('(b.user_id = ? OR l.borrower_id = ?)', [userId, userId]),
    _ => ('', <Object>[]),
  };
  if (where.isEmpty) {
    return validationError('role must be "lent" or "borrowed"');
  }

  final total = db
      .select(
        'SELECT COUNT(*) AS n FROM loans l JOIN books b ON b.id = l.book_id '
        'WHERE $where',
        args,
      )
      .first['n'] as int;
  final rows = db.select(
    '$_select WHERE $where ORDER BY l.id DESC LIMIT ? OFFSET ?',
    [...args, limit, (page - 1) * limit],
  );

  return jsonResponse({
    'items': rows.map(_toJson).toList(),
    'page': page,
    'limit': limit,
    'total': total,
  });
}

/// POST /loans  {bookId, dueDate: "YYYY-MM-DD"} -> 201 loan
/// The current user borrows someone else's available book.
Future<Response> createLoan(Request request) async {
  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  final bookId = body['bookId'];
  if (bookId is! int) return validationError('bookId is required');

  final due = DateTime.tryParse(stringField(body, 'dueDate') ?? '');
  if (due == null) {
    return validationError('dueDate is required, format YYYY-MM-DD');
  }
  final dueDate = DateTime(due.year, due.month, due.day);
  final today = _today();
  if (!dueDate.isAfter(today)) {
    return validationError('dueDate must be in the future');
  }
  if (dueDate.difference(today).inDays > maxLoanDays) {
    return validationError('A loan cannot be longer than $maxLoanDays days');
  }

  final books = db.select('SELECT * FROM books WHERE id = ?', [bookId]);
  if (books.isEmpty) return notFound('Book not found');
  final book = books.first;
  final userId = currentUserId(request);
  if (book['user_id'] == userId) {
    return validationError('You cannot borrow your own book');
  }
  if (book['status'] != 'available') {
    return validationError('The book is already lent');
  }

  // Check-then-write is safe: these sqlite calls are synchronous, so no other
  // request can run between the status check above and the update below.
  final id = transaction(() {
    db.execute(
      'INSERT INTO loans (book_id, borrower_id, start_date, due_date, status, '
      'created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [bookId, userId, isoDate(today), isoDate(dueDate), 'active', nowIso()],
    );
    final id = db.lastInsertRowId;
    db.execute("UPDATE books SET status = 'lent' WHERE id = ?", [bookId]);
    return id;
  });
  return jsonResponse(_toJson(_find(userId, '$id')!), status: 201);
}

/// GET /loans/{id} -> 200 loan | 404
Future<Response> getLoan(Request request) async {
  final row = _find(currentUserId(request), request.params['id']);
  if (row == null) return notFound('Loan not found');
  return jsonResponse(_toJson(row));
}

/// PUT /loans/{id}  {status: "returned"} -> 200 loan | 404
/// Marks the book returned; the book becomes available again.
Future<Response> updateLoan(Request request) async {
  final userId = currentUserId(request);
  final row = _find(userId, request.params['id']);
  if (row == null) return notFound('Loan not found');

  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  final status = stringField(body, 'status');
  if (status == row['status']) return jsonResponse(_toJson(row)); // no change
  if (status != 'returned') {
    return validationError('status can only be changed to "returned"');
  }

  transaction(() {
    db.execute(
      "UPDATE loans SET status = 'returned' WHERE id = ?",
      [row['id']],
    );
    db.execute(
      "UPDATE books SET status = 'available' WHERE id = ?",
      [row['book_id']],
    );
  });
  return jsonResponse(_toJson(_find(userId, '${row['id']}')!));
}

/// DELETE /loans/{id} -> 204 | 404
/// Deleting an active loan also frees the book.
Future<Response> deleteLoan(Request request) async {
  final row = _find(currentUserId(request), request.params['id']);
  if (row == null) return notFound('Loan not found');

  transaction(() {
    if (row['status'] == 'active') {
      db.execute(
        "UPDATE books SET status = 'available' WHERE id = ?",
        [row['book_id']],
      );
    }
    db.execute('DELETE FROM loans WHERE id = ?', [row['id']]);
  });
  return Response(204);
}
