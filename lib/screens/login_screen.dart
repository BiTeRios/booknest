import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth_api.dart';
import '../data/result.dart';
import '../models/book_list_model.dart';
import '../models/loans_model.dart';
import '../models/session_model.dart';
import '../validators.dart';

/// Вход и регистрация на сервере. Валидация из L3 осталась без изменений;
/// валидный submit идёт на backend, token сохраняется в shared_preferences.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // Эфемерное состояние экрана — setState, не модели.
  bool _obscurePassword = true;
  bool _isRegister = false; // вход ↔ регистрация
  bool _busy = false; // запрос летит — кнопка гаснет (без двойного submit)

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута
    final auth = context.read<AuthApi>();
    final email = _emailCtrl.text.trim();

    setState(() => _busy = true);
    final result = _isRegister
        ? await auth.register(email, _passwordCtrl.text, _nameCtrl.text.trim())
        : await auth.login(email, _passwordCtrl.text);
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);

    switch (result) {
      case Ok(:final value):
        context.read<SessionModel>().signIn(
          email: value.email,
          name: value.name,
        );
        _reloadData();
        // go, НЕ push: login уходит из стека — «назад» не вернёт в него
        // уже вошедшего пользователя.
        context.go('/books');
      case Err(:final msg):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// Данные зависят от того, КТО вошёл: после входа (в том числе под другим
  /// пользователем) списки загружаются заново. Модель, созданная прямо сейчас,
  /// уже грузится сама (..load() в корне) — второй запрос ей не нужен.
  void _reloadData() {
    for (final model in [
      context.read<LibraryModel>(),
      context.read<CommunityModel>(),
    ]) {
      if (!model.isLoading) model.load();
    }
    final loans = context.read<LoansModel>();
    if (!loans.isLoading) loans.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                // после первого касания поле перепроверяется при каждом вводе
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'BookNest',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRegister
                          ? 'Создайте аккаунт'
                          : 'Личная библиотека и обмен книгами',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: validateName,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Показать пароль'
                              : 'Скрыть пароль',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegister ? 'Зарегистрироваться' : 'Войти'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister
                            ? 'Уже есть аккаунт? Войдите'
                            : 'Нет аккаунта? Зарегистрируйтесь',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
