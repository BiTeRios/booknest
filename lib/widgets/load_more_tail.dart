import 'package:flutter/material.dart';

/// Хвост списка с пагинацией: пока есть ещё страницы — маленький spinner,
/// который сам просит следующую; если догрузка упала — ошибка и «Повторить».
class LoadMoreTail extends StatelessWidget {
  final String? error;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  const LoadMoreTail({
    super.key,
    required this.error,
    required this.onLoadMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error case final message?) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      );
    }
    // Хвост виден — значит, пользователь долистал: просим следующую страницу.
    // Модель не извещает синхронно, поэтому звать её из build безопасно.
    onLoadMore();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
