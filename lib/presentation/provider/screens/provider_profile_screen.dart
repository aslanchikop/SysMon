// 🐾 Provider Profile Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/auth_provider.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кабинет исполнителя'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Аватар и имя
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      authState.fullName?.isNotEmpty == true
                          ? authState.fullName![0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authState.fullName ?? 'Представитель бизнеса',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.user?.email ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      'Режим исполнителя',
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Настройки
            Text(
              'Настройки клиники / салона',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  // Смена языка
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Язык приложения'),
                    trailing: DropdownButton<String>(
                      value: context.locale.languageCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'ru',
                          child: Text('Русский'),
                        ),
                        DropdownMenuItem(
                          value: 'kk',
                          child: Text('Қазақша'),
                        ),
                      ],
                      onChanged: (langCode) {
                        if (langCode != null) {
                          context.setLocale(Locale(langCode));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Действия аккаунта
            Text(
              'Действия',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  // Переключение на владельца
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: const Text('Перейти в режим владельца'),
                    subtitle: const Text('Поиск услуг для собственных питомцев'),
                    onTap: () async {
                      try {
                        await ref.read(authProvider.notifier).updateRole('owner');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Роль изменена на владельца')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: ${e.toString()}')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1),
                  // Выход
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Выйти из профиля', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      ref.read(authProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
