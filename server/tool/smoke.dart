// Smoke suite: talks to a running server over HTTP, exactly like the app,
// and checks the template contract (auth, notes, files, errors) plus the
// BookNest routes (books, loans). Every run uses fresh users, so it can be
// repeated against the same database.
//
// Run (server started):  dart run tool/smoke.dart --base-url http://localhost:8080

import 'dart:convert';
import 'dart:io';

late final Uri base;
final _client = HttpClient();
var _passed = 0;
var _failed = 0;

class Res {
  Res(this.status, this.text, this.bytes);
  final int status;
  final String text;
  final List<int> bytes;

  dynamic get json => jsonDecode(text);
  String? get code => (json as Map)['error']?['code'] as String?;
}

Future<Res> call(
  String method,
  String path, {
  String? token,
  Object? json,
  Map<String, String>? query,
  List<int>? raw,
  String? contentType,
}) async {
  final uri = base.replace(path: path, queryParameters: query);
  final req = await _client.openUrl(method, uri);
  if (token != null) req.headers.set('authorization', 'Bearer $token');
  if (json != null) {
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode(json)));
  } else if (raw != null) {
    req.headers.set('content-type', contentType!);
    req.add(raw);
  }
  final res = await req.close();
  final bytes =
      await res.fold<List<int>>([], (all, chunk) => all..addAll(chunk));
  return Res(res.statusCode, utf8.decode(bytes, allowMalformed: true), bytes);
}

void check(String name, bool ok, [Object? detail]) {
  if (ok) {
    _passed++;
    print('  ✓ $name');
  } else {
    _failed++;
    print('  ✗ $name${detail == null ? '' : '  →  $detail'}');
  }
}

void section(String title) => print('\n$title');

/// Registers a fresh user and returns their token.
Future<(String, int)> newUser(String tag) async {
  final email = '$tag.${DateTime.now().microsecondsSinceEpoch}@smoke.test';
  final res = await call('POST', '/auth/register',
      json: {'email': email, 'password': 'parola123', 'name': 'Smoke $tag'});
  final body = res.json as Map;
  return (body['token'] as String, (body['user'] as Map)['id'] as int);
}

/// Calendar date [days] ahead of today (day overflow is normalised by
/// DateTime; adding Duration(days: n) would drift across a DST switch).
String dateIn(int days) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day + days);
  return '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';
}

Future<void> main(List<String> args) async {
  final i = args.indexOf('--base-url');
  base = Uri.parse(i >= 0 ? args[i + 1] : 'http://localhost:8080');
  print('BookNest smoke suite → $base');

  // ---------------------------------------------------------------- template
  section('Шаблон: health, auth, ошибки');
  var r = await call('GET', '/health');
  check('GET /health → 200 {status: ok}',
      r.status == 200 && r.json['status'] == 'ok');
  r = await call('GET', '/notes');
  check('GET /notes без token → 401 UNAUTHORIZED',
      r.status == 401 && r.code == 'UNAUTHORIZED');

  final email = 'ana.${DateTime.now().microsecondsSinceEpoch}@smoke.test';
  r = await call('POST', '/auth/register',
      json: {'email': email, 'password': 'parola123', 'name': 'Ana'});
  check('POST /auth/register → 201 token + user',
      r.status == 201 && r.json['token'] is String);
  final tokenA = r.json['token'] as String;
  final idA = r.json['user']['id'] as int;
  r = await call('POST', '/auth/register',
      json: {'email': email, 'password': 'parola123', 'name': 'Ana'});
  check('тот же email → 409 EMAIL_TAKEN',
      r.status == 409 && r.code == 'EMAIL_TAKEN');
  r = await call('POST', '/auth/register',
      json: {'email': 'x@y.z', 'password': 'p'});
  check('register без name → 400 VALIDATION_ERROR',
      r.status == 400 && r.code == 'VALIDATION_ERROR');
  r = await call('POST', '/auth/login',
      json: {'email': email, 'password': 'wrong-pass'});
  check('login с неверным паролем → 401',
      r.status == 401 && r.code == 'UNAUTHORIZED');
  r = await call('POST', '/auth/login',
      json: {'email': email, 'password': 'parola123'});
  check('login → 200 token', r.status == 200 && r.json['token'] is String);
  r = await call('GET', '/me', token: tokenA);
  check('GET /me → 200 текущий пользователь',
      r.status == 200 && r.json['email'] == email);
  r = await call('GET', '/notes', token: 'not.a.token');
  check('испорченный token → 401', r.status == 401);

  section('Шаблон: notes (пример CRUD)');
  r = await call('POST', '/notes',
      token: tokenA, json: {'title': 'Покупки', 'content': 'молоко'});
  check('POST /notes → 201, id от сервера',
      r.status == 201 && r.json['id'] is int);
  final noteId = r.json['id'] as int;
  r = await call('GET', '/notes', token: tokenA, query: {'search': 'Покуп'});
  check('GET /notes?search= → пагинированный конверт',
      r.status == 200 && r.json['total'] == 1 && r.json['items'] is List);
  r = await call('PUT', '/notes/$noteId',
      token: tokenA, json: {'title': 'Список', 'content': ''});
  check(
      'PUT /notes/{id} → 200', r.status == 200 && r.json['title'] == 'Список');
  final (tokenB, idB) = await newUser('bob');
  r = await call('GET', '/notes/$noteId', token: tokenB);
  check('чужая заметка → 404, а не 403',
      r.status == 404 && r.code == 'NOT_FOUND');
  r = await call('DELETE', '/notes/$noteId', token: tokenA);
  check('DELETE /notes/{id} → 204, пустое тело',
      r.status == 204 && r.text.isEmpty);
  r = await call('GET', '/nope');
  check('неизвестный маршрут → 404 NOT_FOUND',
      r.status == 404 && r.code == 'NOT_FOUND');

  section('Шаблон: files');
  const boundary = 'smoke-boundary-42';
  final payload = utf8.encode('cover bytes ✓');
  final multipart = <int>[
    ...utf8.encode('--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="cover.txt"\r\n'
        'Content-Type: text/plain\r\n\r\n'),
    ...payload,
    ...utf8.encode('\r\n--$boundary--\r\n'),
  ];
  r = await call('POST', '/files',
      token: tokenA,
      raw: multipart,
      contentType: 'multipart/form-data; boundary=$boundary');
  check('POST /files (multipart) → 201 url',
      r.status == 201 && (r.json['url'] as String).startsWith('/files/'));
  final fileUrl = r.json['url'] as String;
  r = await call('GET', fileUrl);
  check('GET /files/{id} → те же байты, без token',
      r.status == 200 && utf8.decode(r.bytes) == 'cover bytes ✓');

  // ---------------------------------------------------------------- books
  section('BookNest: books');
  r = await call('POST', '/books',
      token: tokenA, json: {'author': 'Без названия'});
  check('POST /books без title → 400',
      r.status == 400 && r.code == 'VALIDATION_ERROR');
  r = await call('POST', '/books',
      token: tokenA, json: {'title': 'Без автора'});
  check('POST /books без author → 400',
      r.status == 400 && r.code == 'VALIDATION_ERROR');
  r = await call('POST', '/books', token: tokenA, json: {
    'title': 'Мастер и Маргарита',
    'author': 'Михаил Булгаков',
    'genre': 'Классика',
    'coverUrl': fileUrl,
  });
  check(
      'POST /books → 201, available, владелец — автор запроса',
      r.status == 201 &&
          r.json['status'] == 'available' &&
          r.json['ownerId'] == idA &&
          r.json['coverUrl'] == fileUrl);
  final bookId = r.json['id'] as int;
  for (final t in ['Дюна', '1984', 'Ion']) {
    await call('POST', '/books',
        token: tokenA,
        json: {'title': t, 'author': 'Автор', 'genre': 'Фантастика'});
  }
  r = await call('GET', '/books', token: tokenA, query: {'scope': 'mine'});
  check('GET /books?scope=mine → 4 книги',
      r.status == 200 && r.json['total'] == 4);
  r = await call('GET', '/books',
      token: tokenA, query: {'scope': 'mine', 'limit': '3', 'page': '2'});
  check('пагинация: limit=3, page=2 → 1 книга',
      r.json['page'] == 2 && (r.json['items'] as List).length == 1);
  r = await call('GET', '/books', token: tokenA, query: {'search': 'мастер'});
  check('поиск без учёта регистра по кириллице', r.json['total'] == 1);
  r = await call('GET', '/books',
      token: tokenA, query: {'genre': 'Фантастика'});
  check('фильтр по жанру', r.json['total'] == 3);
  r = await call('GET', '/books', token: tokenB, query: {'scope': 'community'});
  final community =
      (r.json['items'] as List).where((b) => b['ownerId'] == idA).toList();
  check('сообщество видит книги других с ownerName',
      community.length == 4 && community.every((b) => b['ownerName'] == 'Ana'));
  r = await call('GET', '/books', token: tokenB, query: {'scope': 'mine'});
  check('в «моих» у другого пользователя чужих книг нет', r.json['total'] == 0);
  r = await call('GET', '/books', token: tokenA, query: {'scope': 'all'});
  check('неверный scope → 400', r.status == 400);
  r = await call('GET', '/books/$bookId', token: tokenB);
  check('GET /books/{id} чужой книги → 200 (видимость сообщества)',
      r.status == 200);
  r = await call('GET', '/books/999999', token: tokenA);
  check('GET /books/{id} несуществующей → 404',
      r.status == 404 && r.code == 'NOT_FOUND');
  r = await call('PUT', '/books/$bookId',
      token: tokenB, json: {'title': 'X', 'author': 'Y'});
  check('PUT чужой книги → 404', r.status == 404);
  r = await call('PUT', '/books/$bookId', token: tokenA, json: {
    'title': 'Мастер и Маргарита (ил.)',
    'author': 'Михаил Булгаков',
    'genre': 'Классика',
    'status': 'lent'
  });
  check(
      'PUT своей книги → 200, status от PUT не меняется',
      r.status == 200 &&
          r.json['title'] == 'Мастер и Маргарита (ил.)' &&
          r.json['status'] == 'available');

  // ---------------------------------------------------------------- loans
  section('BookNest: loans');
  r = await call('POST', '/books',
      token: tokenB, json: {'title': 'Своя', 'author': 'Bob'});
  final ownBookB = r.json['id'] as int;
  r = await call('POST', '/loans',
      token: tokenB, json: {'bookId': ownBookB, 'dueDate': dateIn(7)});
  check('взять свою книгу → 400',
      r.status == 400 && r.code == 'VALIDATION_ERROR');
  r = await call('POST', '/loans',
      token: tokenB, json: {'bookId': bookId, 'dueDate': dateIn(0)});
  check('срок сегодня → 400 (должен быть в будущем)', r.status == 400);
  r = await call('POST', '/loans',
      token: tokenB, json: {'bookId': bookId, 'dueDate': dateIn(61)});
  check('срок больше 60 дней → 400', r.status == 400);
  r = await call('POST', '/loans', token: tokenB, json: {'bookId': bookId});
  check('без dueDate → 400', r.status == 400);
  r = await call('POST', '/loans',
      token: tokenB, json: {'bookId': 999999, 'dueDate': dateIn(7)});
  check('несуществующая книга → 404', r.status == 404);
  r = await call('POST', '/loans',
      token: tokenB, json: {'bookId': bookId, 'dueDate': dateIn(14)});
  check(
      'POST /loans → 201 active, заёмщик и владелец заполнены',
      r.status == 201 &&
          r.json['status'] == 'active' &&
          r.json['borrowerId'] == idB &&
          r.json['ownerId'] == idA &&
          r.json['dueDate'] == dateIn(14));
  final loanId = r.json['id'] as int;
  r = await call('GET', '/books/$bookId', token: tokenA);
  check('книга стала lent', r.json['status'] == 'lent');
  r = await call('POST', '/loans',
      token: tokenB, json: {'bookId': bookId, 'dueDate': dateIn(7)});
  check('повторно взять выданную книгу → 400', r.status == 400);
  r = await call('GET', '/loans', token: tokenA, query: {'role': 'lent'});
  check('владелец видит обмен в role=lent',
      (r.json['items'] as List).any((l) => l['id'] == loanId));
  r = await call('GET', '/loans', token: tokenB, query: {'role': 'borrowed'});
  check('заёмщик видит обмен в role=borrowed',
      (r.json['items'] as List).any((l) => l['id'] == loanId));
  r = await call('GET', '/loans', token: tokenB, query: {'role': 'lent'});
  check('у заёмщика в role=lent этого обмена нет',
      !(r.json['items'] as List).any((l) => l['id'] == loanId));
  final (tokenC, _) = await newUser('carol');
  r = await call('GET', '/loans/$loanId', token: tokenC);
  check('посторонний → 404 на чужой обмен', r.status == 404);
  r = await call('DELETE', '/books/$bookId', token: tokenA);
  check('удалить выданную книгу → 400', r.status == 400);
  r = await call('PUT', '/loans/$loanId',
      token: tokenA, json: {'status': 'lost'});
  check('PUT неизвестного статуса → 400', r.status == 400);
  r = await call('PUT', '/loans/$loanId',
      token: tokenA, json: {'status': 'returned'});
  check('PUT /loans/{id} returned → 200',
      r.status == 200 && r.json['status'] == 'returned');
  r = await call('GET', '/books/$bookId', token: tokenA);
  check('книга снова available', r.json['status'] == 'available');
  r = await call('DELETE', '/loans/$loanId', token: tokenB);
  check('DELETE /loans/{id} → 204', r.status == 204 && r.text.isEmpty);
  r = await call('DELETE', '/books/$bookId', token: tokenA);
  check('DELETE /books/{id} → 204', r.status == 204 && r.text.isEmpty);
  r = await call('GET', '/books/$bookId', token: tokenA);
  check('удалённая книга → 404', r.status == 404);

  _client.close();
  final total = _passed + _failed;
  print('\n${_failed == 0 ? 'PASS' : 'FAIL'} — $_passed/$total checks passed');
  exit(_failed == 0 ? 0 : 1);
}
