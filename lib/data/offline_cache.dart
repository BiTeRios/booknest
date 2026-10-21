import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Снимок списка из кэша: сами записи и момент, когда их отдал сервер.
class CachedList<T> {
  const CachedList(this.items, this.savedAt);
  final List<T> items;
  final DateTime savedAt;
}

/// Offline-кэш (L6): последние успешные ответы сервера на списки,
/// по ключу запроса, в shared_preferences в виде JSON.
/// Хранятся только списки, которые уже видел вошедший пользователь;
/// при выходе и при 401 кэш стирается вместе с токеном.
class OfflineCache {
  static const _prefix = 'cache:'; // все ключи кэша — с одним префиксом

  Future<void> putList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$key',
      jsonEncode({'savedAt': DateTime.now().toIso8601String(), 'items': items}),
    );
  }

  /// null — такого списка в кэше нет (или запись повреждена).
  Future<CachedList<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      '$_prefix$key',
    );
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return CachedList(
        (data['items'] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
        DateTime.parse(data['savedAt'] as String),
      );
    } on FormatException {
      return null; // битая запись — как будто кэша нет
    } on TypeError {
      return null;
    }
  }

  /// Выход / смена пользователя: чужие книги не должны пережить logout.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await prefs.remove(key);
    }
  }
}
