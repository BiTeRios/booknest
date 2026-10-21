import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:booknest/data/file_api.dart';
import 'package:booknest/data/result.dart';
import 'package:booknest/data/token_store.dart';

void main() {
  late File cover;
  late List<http.Request> requests;
  late int unauthorized;

  FileApi files(http.Response response) => FileApi(
    'http://api.test',
    TokenStore(),
    onUnauthorized: () => unauthorized++,
    client: MockClient((req) async {
      requests.add(req);
      return response;
    }),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'jwt-123'});
    requests = [];
    unauthorized = 0;
    final dir = Directory.systemTemp.createTempSync('booknest_test');
    cover = File('${dir.path}/cover.jpg')..writeAsBytesSync([0xFF, 0xD8, 1, 2]);
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  test('201: multipart с полем «file», ответ — относительный url', () async {
    final result = await files(
      http.Response(jsonEncode({'url': '/files/7'}), 201),
    ).upload(cover.path);

    expect((result as Ok<String>).value, '/files/7');
    final req = requests.single;
    expect(req.method, 'POST');
    expect(req.url.path, '/files');
    expect(req.headers['Authorization'], 'Bearer jwt-123');
    expect(req.headers['content-type'], startsWith('multipart/form-data'));
    expect(
      latin1.decode(req.bodyBytes),
      contains('name="file"; filename="cover.jpg"'),
    );
  });

  test('400 «слишком большой» — перевод из конверта ошибки', () async {
    final result = await files(
      http.Response(
        jsonEncode({
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'File too large: the upload limit is 5 MB',
          },
        }),
        400,
      ),
    ).upload(cover.path);
    expect((result as Err).msg, 'Файл больше 5 МБ');
  });

  test('401 — token стёрт, корень извещён', () async {
    final result = await files(http.Response('', 401)).upload(cover.path);
    expect((result as Err).msg, 'Сессия истекла — войдите снова');
    expect(unauthorized, 1);
    expect(await TokenStore().read(), isNull);
  });

  test('сеть упала — isNetwork', () async {
    final api = FileApi(
      'http://api.test',
      TokenStore(),
      client: MockClient((_) async => throw const SocketException('refused')),
    );
    final result = await api.upload(cover.path);
    expect((result as Err).isNetwork, isTrue);
  });
}
