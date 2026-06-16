// 🐾 Provider Services CRUD Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/data_providers.dart';

// Провайдер для получения ID заведения текущего авторизованного исполнителя
final currentProviderIdProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId == null) return null;
  
  final supabase = ref.watch(supabaseClientProvider);
  final data = await supabase
      .from('providers')
      .select('id')
      .eq('profile_id', userId)
      .maybeSingle();
      
  return data?['id'] as String?;
});

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  void _openAddServiceSheet(BuildContext context, String providerId, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddServiceBottomSheet(providerId: providerId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerIdAsync = ref.watch(currentProviderIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('tabs.services')),
      ),
      body: providerIdAsync.when(
        data: (providerId) {
          if (providerId == null) {
            return const Center(child: Text('У вас еще не настроен профиль бизнеса. Обратитесь в поддержку.'));
          }

          final servicesAsync = ref.watch(providerServicesProvider(providerId));

          return servicesAsync.when(
            data: (services) {
              if (services.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.room_service_rounded,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'У вас нет добавленных услуг',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Добавьте услуги, чтобы клиенты могли записываться.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _openAddServiceSheet(context, providerId, ref),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Добавить услугу'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  final isActive = service['active'] ?? true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['name'],
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (service['description'] != null) ...[
                                  Text(
                                    service['description'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 16, color: theme.colorScheme.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${service['duration_min']} мин',
                                      style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.monetization_on_rounded, size: 16, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${service['price']} ₸',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Переключатель активна/неактивна
                          Switch(
                            value: isActive,
                            onChanged: (val) async {
                              final supabase = ref.read(supabaseClientProvider);
                              try {
                                await supabase
                                    .from('services')
                                    .update({'active': val})
                                    .eq('id', service['id']);
                                ref.invalidate(providerServicesProvider(providerId));
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ошибка обновления статуса: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Ошибка загрузки услуг: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
      floatingActionButton: providerIdAsync.maybeWhen(
        data: (providerId) => providerId != null
            ? FloatingActionButton.extended(
                onPressed: () => _openAddServiceSheet(context, providerId, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить услугу'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

// BottomSheet формы добавления услуги
class _AddServiceBottomSheet extends ConsumerStatefulWidget {
  final String providerId;

  const _AddServiceBottomSheet({required this.providerId});

  @override
  ConsumerState<_AddServiceBottomSheet> createState() => _AddServiceBottomSheetState();
}

class _AddServiceBottomSheetState extends ConsumerState<_AddServiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseClientProvider);

    try {
      await supabase.from('services').insert({
        'provider_id': widget.providerId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        'price': int.parse(_priceController.text),
        'duration_min': int.parse(_durationController.text),
        'active': true,
      });

      // Обновляем список услуг
      ref.invalidate(providerServicesProvider(widget.providerId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Услуга успешно добавлена!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Добавить услугу',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Название услуги
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название услуги',
                    hintText: 'Гигиеническая стрижка',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите название услуги';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Описание услуги
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    hintText: 'Включает мытье, сушку, стрижку когтей...',
                  ),
                ),
                const SizedBox(height: 16),

                // Цена услуги
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Цена (₸)',
                    hintText: '8000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите цену';
                    if (int.tryParse(value) == null) return 'Введите корректное число';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Длительность услуги
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Длительность (минут)',
                    hintText: '60',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите длительность';
                    if (int.tryParse(value) == null) return 'Введите корректное число';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Кнопка сохранения
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(tr('save')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
