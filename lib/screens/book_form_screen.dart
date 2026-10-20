import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../validators.dart';

/// Форма книги: новая (/books/new) или редактирование (/books/7/edit).
/// На L3 форма функциональна локально: отказывает плохим данным и подтверждает
/// хорошие, но данные никуда не сохраняются — состояние придёт на L4.
class BookFormScreen extends StatefulWidget {
  /// null — новая книга; иначе id редактируемой книги из адреса.
  final int? bookId;

  const BookFormScreen({super.key, this.bookId});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  String? _genre;

  bool get _isEdit => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    // Режим редактирования: поля заполняются данными книги из адреса.
    final book = mockMyBooks.where((b) => b.id == widget.bookId).firstOrNull;
    if (book != null) {
      _titleCtrl.text = book.title;
      _authorCtrl.text = book.author;
      _genre = book.genre;
    }
  }

  @override
  void dispose() {
    // Кто создаёт контроллер, тот и освобождает — по dispose() на каждый.
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return; // ошибки уже на экране
    final title = _titleCtrl.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEdit
              ? 'Изменения сохранены: «$title»'
              : 'Книга «$title» добавлена',
        ),
      ),
    );
    context.pop(); // открыто push-ем → закрывается pop-ом
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Редактирование' : 'Новая книга')),
      body: Form(
        key: _formKey,
        // после первого касания поле перепроверяется при каждом вводе
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 144,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Загрузка обложки станет доступна после подключения сервера',
                    ),
                  ),
                ),
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Загрузить обложку'),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Название *',
                border: OutlineInputBorder(),
              ),
              validator: validateBookTitle,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _authorCtrl,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              // в имени автора не бывает цифр — их нельзя даже ввести
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\d')),
              ],
              decoration: const InputDecoration(
                labelText: 'Автор *',
                border: OutlineInputBorder(),
              ),
              validator: validateAuthor,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _genre,
              decoration: const InputDecoration(
                labelText: 'Жанр *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final genre in bookGenres)
                  DropdownMenuItem(value: genre, child: Text(genre)),
              ],
              onChanged: (value) => _genre = value,
              validator: validateGenre,
            ),
            const SizedBox(height: 8),
            Text(
              '* — обязательные поля',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
