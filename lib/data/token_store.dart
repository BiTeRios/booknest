import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_user.dart';

/// Пропуск (JWT) поверх shared_preferences. Остальной код не знает, где он спит.
/// Пароль не пишется локально НИКОГДА: token заменим и истекает, пароль —
/// ключ от всего дома.
class TokenStore {
  static const _tokenKey = 'auth_token'; // ключи — константы, в одном месте
  static const _userKey = 'auth_user';

  /// null — не вошёл.
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  /// login → setString: токен и профиль (имя, e-mail) для экрана профиля.
  Future<void> save(String token, AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Профиль последнего вошедшего — чтобы после перезапуска не звать сервер.
  Future<AppUser?> readUser() async {
    final raw = (await SharedPreferences.getInstance()).getString(_userKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// logout И 401: мёртвый пропуск выбрасывается.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
