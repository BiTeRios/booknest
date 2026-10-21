import 'package:flutter/foundation.dart';

/// Разделяемое состояние (L6): показаны ли сейчас сохранённые данные вместо
/// свежих с сервера. Пишет корень композиции (по сигналам кэширующих
/// хранилищ), читает баннер в AppShell.
class OfflineStatus extends ChangeNotifier {
  DateTime? _cachedAt;

  bool get isOffline => _cachedAt != null;

  /// Когда сервер отдал данные, которые сейчас на экране.
  DateTime? get cachedAt => _cachedAt;

  /// null — данные свежие (сервер ответил); иначе — момент снимка из кэша.
  void report(DateTime? cachedAt) {
    if (cachedAt == _cachedAt) return; // без лишних перестроек
    _cachedAt = cachedAt;
    notifyListeners();
  }
}
