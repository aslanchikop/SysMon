// 🐾 Role Selection Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole; // 'owner' или 'provider'

  Future<void> _submit() async {
    if (_selectedRole == null) return;

    try {
      await ref.read(authProvider.notifier).updateRole(_selectedRole!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления роли: ${e.toString()}'),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Заголовок
              Text(
                tr('role_selection'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Выберите тип вашего аккаунта. Роль можно будет сменить в профиле.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 60),

              // Карточка: Владелец
              Expanded(
                child: _RoleCard(
                  title: tr('owner'),
                  description: 'Записывайте питомца в клиники и груминг, ведите медкарту и следите за здоровьем.',
                  icon: Icons.pets_rounded,
                  isSelected: _selectedRole == 'owner',
                  onTap: () => setState(() => _selectedRole = 'owner'),
                ),
              ),
              const SizedBox(height: 20),

              // Карточка: Провайдер
              Expanded(
                child: _RoleCard(
                  title: tr('provider'),
                  description: 'Управляйте своим расписанием, ведите учет клиентов, публикуйте список услуг и цены.',
                  icon: Icons.business_center_rounded,
                  isSelected: _selectedRole == 'provider',
                  onTap: () => setState(() => _selectedRole = 'provider'),
                ),
              ),
              const SizedBox(height: 60),

              // Кнопка подтверждения
              ElevatedButton(
                onPressed: _selectedRole == null || authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(tr('next')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(isSelected ? 0.8 : 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
