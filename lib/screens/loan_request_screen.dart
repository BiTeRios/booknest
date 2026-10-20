import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/format.dart';
import '../data/mock_data.dart';
import '../validators.dart';
import '../widgets/book_card.dart';

/// Запрос книги у владельца (/community/7/request): срок возврата и сообщение.
/// На L3 запрос только валидируется и подтверждается; запись Loan создаётся на L4.
class LoanRequestScreen extends StatefulWidget {
  final int bookId;

  const LoanRequestScreen({super.key, required this.bookId});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dueCtrl = TextEditingController(); // показывает выбранную дату
  final _messageCtrl = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _dueCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 14)),
      // сегодня и дальше 60 дней выбрать можно — их отвергнет validator
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Вернуть до',
    );
    if (picked == null) return;
    _dueDate = picked;
    _dueCtrl.text = formatDate(picked);
  }

  void _submit(Book book) {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Запрос отправлен: «${book.title}» до ${formatDate(_dueDate!)}',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final book = mockCommunityBooks
        .where((b) => b.id == widget.bookId)
        .firstOrNull;
    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Книга не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Запрос книги')),
      body: Form(
        key: _formKey,
        // после первого касания поле перепроверяется при каждом вводе
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BookCard(book: book, showOwner: true),
            const SizedBox(height: 16),
            Text(
              'Владелец получит запрос и подтвердит обмен. '
              'Срок возврата — не дольше $maxLoanDays дней.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dueCtrl,
              readOnly: true, // дата вводится только через календарь
              onTap: _pickDueDate,
              decoration: const InputDecoration(
                labelText: 'Вернуть до *',
                suffixIcon: Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (_) => validateDueDate(_dueDate),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageCtrl,
              maxLength: 200,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Сообщение владельцу',
                hintText: 'Например: верну на паре в четверг',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: book.status == BookStatus.available
                  ? () => _submit(book)
                  : null,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                book.status == BookStatus.available
                    ? 'Отправить запрос'
                    : 'Книга сейчас выдана',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
