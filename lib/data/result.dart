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
  const Err(this.msg);
  final String msg;
}
