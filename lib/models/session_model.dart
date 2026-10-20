import 'package:flutter/foundation.dart';

/// Разделяемое состояние сессии: кто вошёл. Пишет экран входа, читает профиль.
/// Чистый Dart: ChangeNotifier приходит из foundation, это не widget.
class SessionModel extends ChangeNotifier {
  String? _email;
  String? _name;

  String? get email => _email;

  /// Имя пользователя; на L4 неизвестно (вход локальный), на L5 придёт с сервера.
  String? get name => _name;

  bool get isSignedIn => _email != null;

  void signIn({required String email, String? name}) {
    _email = email;
    _name = name;
    notifyListeners(); // весть уходит ко ВСЕМ подписчикам
  }

  void signOut() {
    _email = null;
    _name = null;
    notifyListeners();
  }
}
