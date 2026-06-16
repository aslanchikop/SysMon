// 🐾 Pet List and Add Pet Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/data_providers.dart';

class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  void _openAddPetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddPetBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('pet.my_pets')),
      ),
      body: petsAsync.when(
        data: (pets) {
          if (pets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets_rounded,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('pet.no_pets'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openAddPetSheet(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(tr('pet.add_pet')),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final isDog = pet['species'] == 'dog';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Иконка питомца
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDog ? Icons.pets_rounded : Icons.pets_rounded,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Информация о питомце
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet['name'],
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pet['breed'] ?? "Без породы"} • ${pet['weight'] ?? "?"} кг',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (pet['birth_date'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Дата рождения: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(pet['birth_date']))}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                            ]
                          ],
                        ),
                      ),
                      
                      // Значок Медкарты
                      IconButton(
                        icon: const Icon(Icons.medical_services_outlined, color: Colors.grey),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('В MVP демо-версии медицинская карта генерируется автоматически при записи к врачу.'),
                            ),
                          );
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
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
      floatingActionButton: petsAsync.maybeWhen(
        data: (pets) => pets.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _openAddPetSheet(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: Text(tr('pet.add_pet')),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

// BottomSheet формы добавления питомца
class _AddPetBottomSheet extends ConsumerStatefulWidget {
  const _AddPetBottomSheet();

  @override
  ConsumerState<_AddPetBottomSheet> createState() => _AddPetBottomSheetState();
}

class _AddPetBottomSheetState extends ConsumerState<_AddPetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedSpecies = 'dog';
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final double? weight = _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text.replaceAll(',', '.'))
          : null;

      await ref.read(petNotifierProvider.notifier).addPet(
            name: _nameController.text.trim(),
            species: _selectedSpecies,
            breed: _breedController.text.trim().isNotEmpty ? _breedController.text.trim() : null,
            birthDate: _selectedBirthDate,
            weight: weight,
          );

      if (mounted) {
        Navigator.of(context).pop(); // Закрываем форму
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Питомец успешно добавлен!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    final petState = ref.watch(petNotifierProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
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
                  tr('pet.add_pet'),
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Имя
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: tr('pet.name'),
                    hintText: 'Рекс',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите кличку';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Вид животного (Ит/Мысық)
                Text(
                  tr('pet.species'),
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        selected: _selectedSpecies == 'dog',
                        label: Text(tr('pet.dog')),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSpecies = 'dog');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        selected: _selectedSpecies == 'cat',
                        label: Text(tr('pet.cat')),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSpecies = 'cat');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Порода
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Порода',
                    hintText: 'Немецкая овчарка (или оставьте пустым)',
                  ),
                ),
                const SizedBox(height: 16),

                // Вес
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Вес (кг)',
                    hintText: '12.5',
                  ),
                ),
                const SizedBox(height: 16),

                // Дата рождения (Выбор даты)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_rounded),
                  title: Text(
                    _selectedBirthDate == null
                        ? 'Выбрать дату рождения'
                        : 'Дата рождения: ${DateFormat('dd.MM.yyyy').format(_selectedBirthDate!)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedBirthDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Кнопка сохранения
                ElevatedButton(
                  onPressed: petState.isLoading ? null : _submit,
                  child: petState.isLoading
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
