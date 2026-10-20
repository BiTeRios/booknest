import 'package:flutter/material.dart';

/// Диалог подтверждения: «просишь решение — диалог с await».
/// Возвращает true, только если пользователь нажал кнопку подтверждения.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    // Закрываем через dialogCtx: под вложенными навигаторами вкладок
    // pop на context-е экрана закрыл бы не диалог, а что-то другое.
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  // Диалог, закрытый мимо кнопок (тап по фону, «назад»), даёт null — это «нет».
  return ok == true;
}
