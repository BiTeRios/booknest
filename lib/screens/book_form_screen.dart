import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/book.dart';
import '../models/book_list_model.dart';
import '../validators.dart';

/// Форма книги: новая (/books/new) или редактирование (/books/7/edit).
/// Валидный submit пишет через модель (а модель — через Repository);
/// список позади обновляется сам, через notifyListeners.
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

  /// Книга, которую редактируем; null — новая книга.
  Book? _editing;

  /// Эфемерное состояние: запрос в полёте — кнопка гаснет (без двойного submit).
  bool _busy = false;

  bool get _isEdit => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    // Режим редактирования: поля заполняются данными книги из модели.
    // read (не watch): в initState нужно одно значение, а не подписка.
    if (widget.bookId case final id?) {
      _editing = context.read<LibraryModel>().byId(id);
    }
    if (_editing case final book?) {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();
    final library = context.read<LibraryModel>();

    setState(() => _busy = true);
    final error = switch (_editing) {
      final book? => await library.update(
        book.copyWith(title: title, author: author, genre: _genre),
      ),
      // id 0 временный — настоящую идентичность даст хранилище (на L5 — сервер)
      null => await library.add(
        Book.draft(title: title, author: author, genre: _genre!),
      ),
    };
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error))); // данные остаются в полях
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEdit
              ? 'Изменения сохранены: «$title»'
              : 'Книга «$title» добавлена',
        ),
      ),
    );
    context.pop(); // список позади УЖЕ обновился — без единого лишнего вызова
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
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
