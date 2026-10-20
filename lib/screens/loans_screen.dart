import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/loan_tile.dart';

/// «Мои обмены»: выданные мной и взятые мной книги со сроками возврата.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        body: TabBarView(
          children: [
            _LoanList(loans: mockLentLoans, lent: true),
            _LoanList(loans: mockBorrowedLoans, lent: false),
          ],
        ),
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return LoanTile(
          loan: loan,
          lent: lent,
          // возврат отмечает владелец, и только у активного обмена
          action: lent && loan.status == LoanStatus.active
              ? TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Отметить возврат'),
                )
              : null,
        );
      },
    );
  }
}
