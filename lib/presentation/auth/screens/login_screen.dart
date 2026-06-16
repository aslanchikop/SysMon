// 🐾 Login Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      // GoRouter автоматически перенаправит пользователя благодаря слушателю в app_router.dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [const Color(0xFFEAEAFF), Colors.white]
                : [const Color(0xFF131424), const Color(0xFF1A1B2E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Логотип
                    Hero(
                      tag: 'logo',
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pets_rounded,
                          size: 50,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Название
                    Text(
                      tr('app_name'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('owner_home.subtitle'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 48),

                    // Поле ввода почты
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: 'user@example.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите email';
                        }
                        if (!value.contains('@')) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Поле ввода пароля
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен быть не менее 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Кнопка входа
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _submit,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(tr('login')),
                    ),
                    const SizedBox(height: 24),

                    // Переключение языка
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => context.setLocale(const Locale('ru')),
                          child: Text(
                            'Русский',
                            style: TextStyle(
                              fontWeight: context.locale.languageCode == 'ru'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const Text('|'),
                        TextButton(
                          onPressed: () => context.setLocale(const Locale('kk')),
                          child: Text(
                            'Қазақша',
                            style: TextStyle(
                              fontWeight: context.locale.languageCode == 'kk'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ссылка на регистрацию
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Нет аккаунта? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text(
                            'Зарегистрироваться',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
