/// Адрес backend-а. Эмулятор Android не знает «localhost» ноутбука: сервер на
/// ноутбуке для него — 10.0.2.2. Для телефона по Wi-Fi передайте IP ноутбука:
///   flutter run --dart-define=API_BASE=http://192.168.1.10:8080
const apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8080',
);
