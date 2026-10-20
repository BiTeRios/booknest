import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/book.dart';
import '../data/format.dart';
import '../models/book_list_model.dart';
import '../models/loans_model.dart';
import '../validators.dart';
import '../widgets/book_card.dart';
import '../widgets/error_view.dart';

/// Запрос книги у владельца (/community/7/request): срок возврата и сообщение.
/// Валидный submit создаёт запись Loan через LoansModel; книга становится «выдана».
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

  /// Эфемерное состояние: запрос в полёте — кнопка гаснет.
  bool _busy = false;

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

  Future<void> _submit(Book book) async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута
    final community = context.read<CommunityModel>();

    setState(() => _busy = true);
    final error = await context.read<LoansModel>().request(book, _dueDate!);
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error))); // данные остаются в полях
      return;
    }
    // хранилище уже пометило книгу выданной — список сообщества синхронизируется
    community.markStatus(book.id, BookStatus.lent);
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
    final community = context.watch<CommunityModel>();
    final book = community.byId(widget.bookId);
    if (book == null) {
      final Widget body;
      if (community.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (community.error case final error?) {
        body = ErrorView(
          message: error,
          onRetry: () => context.read<CommunityModel>().load(),
        );
      } else {
        body = const Center(child: Text('Книга не существует'));
      }
      return Scaffold(appBar: AppBar(), body: body);
    }

    final available = book.status == BookStatus.available;
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
              onPressed: available && !_busy ? () => _submit(book) : null,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                available ? 'Отправить запрос' : 'Книга сейчас выдана',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
