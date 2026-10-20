import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/book.dart';
import '../data/loan.dart';
import '../models/book_list_model.dart';
import '../models/loans_model.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/loan_tile.dart';

/// Возврат закрывает обмен: подтверждение → запись через модель → SnackBar.
Future<void> _markReturned(BuildContext context, Loan loan) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Книга возвращена?',
    message: '«${loan.bookTitle}» снова станет доступна для обмена.',
    confirmLabel: 'Да, вернули',
  );
  if (!ok || !context.mounted) return;
  final error = await context.read<LoansModel>().markReturned(loan);
  if (!context.mounted) return; // экран может умереть, пока «запрос» летит
  if (error == null) {
    // хранилище уже освободило книгу — библиотека синхронизируется сама
    context.read<LibraryModel>().markStatus(loan.bookId, BookStatus.available);
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? 'Возврат отмечен: «${loan.bookTitle}»')),
  );
}

/// «Мои обмены»: выданные мной и взятые мной книги со сроками возврата.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LoansModel>();

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!,
        onRetry: () => context.read<LoansModel>().load(),
      );
    } else {
      body = TabBarView(
        children: [
          _LoanList(loans: model.lent, lent: true),
          _LoanList(loans: model.borrowed, lent: false),
        ],
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои обмены'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.north_east), text: 'Выданные'),
              Tab(icon: Icon(Icons.south_west), text: 'Взятые'),
            ],
          ),
        ),
        body: body,
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  final List<Loan> loans;
  final bool lent;

  const _LoanList({required this.loans, required this.lent});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Text(
          lent ? 'Вы пока никому не выдали книг' : 'Вы пока не брали книг',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return LoanTile(
          key: ValueKey(loan.id),
          loan: loan,
          lent: lent,
          // возврат отмечает владелец, и только у активного обмена
          action: lent && loan.status == LoanStatus.active
              ? TextButton.icon(
                  onPressed: () => _markReturned(context, loan),
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Отметить возврат'),
                )
              : null,
        );
      },
    );
  }
}
