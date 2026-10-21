/// Вердикт операции с данными: значение или сообщение для экрана.
/// Ожидаемый отказ — это значение, а не исключение, летящее через UI:
/// switch по sealed-типу исчерпывающий, забыть ветку ошибки компилятор не даст.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.msg, {this.isNetwork = false});
  final String msg;

  /// true — не дошли до сервера (нет сети, таймаут). Такой отказ (L6) можно
  /// пережить, показав сохранённые данные; ответ сервера с ошибкой — нельзя.
  final bool isNetwork;
}
