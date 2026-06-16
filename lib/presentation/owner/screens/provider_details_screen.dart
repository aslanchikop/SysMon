// 🐾 Provider Details & Booking flow Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/data_providers.dart';

class ProviderDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> provider;

  const ProviderDetailsScreen({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isClinic = provider['type'] == 'vet_clinic';
    final servicesAsync = ref.watch(providerServicesProvider(provider['id']));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Красивый шапка-баннер
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isClinic
                        ? [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)]
                        : [theme.colorScheme.secondary, theme.colorScheme.secondary.withOpacity(0.7)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    isClinic ? Icons.local_hospital_rounded : Icons.content_cut_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ),
          
          // Детали и описание заведения
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          provider['business_name'],
                          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${provider['rating']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Адрес
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider['address'],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Описание
                  Text(
                    provider['description'] ?? 'Описание отсутствует',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  
                  // Заголовок Услуг
                  Text(
                    'Наши услуги',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          
          // Список Услуг
          servicesAsync.when(
            data: (services) {
              if (services.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Нет доступных услуг.'),
                    ),
                  ),
                );
              }
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = services[index];
                    return _buildServiceItem(context, service, theme, ref);
                  },
                  childCount: services.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Ошибка загрузки услуг: $err')),
            ),
          ),
          
          // Отступ снизу
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, Map<String, dynamic> service, ThemeData theme, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          service['name'],
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              service['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${service['duration_min']} мин',
                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${service['price']} ₸',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _openBookingSheet(context, service, ref),
              child: const Text('Запись', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 BottomSheet для оформления записи
  void _openBookingSheet(BuildContext context, Map<String, dynamic> service, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BookingBottomSheet(provider: provider, service: service);
      },
    );
  }
}

// Внутренний Widget BottomSheet
class _BookingBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> provider;
  final Map<String, dynamic> service;

  const _BookingBottomSheet({
    required this.provider,
    required this.service,
  });

  @override
  ConsumerState<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends ConsumerState<_BookingBottomSheet> {
  String? _selectedPetId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  final _notesController = TextEditingController();

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00', '18:00'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (_selectedPetId == null || _selectedTime == null) return;

    // Вычисляем финальное время
    final parts = _selectedTime!.split(':');
    final bookingDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    try {
      await ref.read(bookingNotifierProvider.notifier).createBooking(
            providerId: widget.provider['id'],
            petId: _selectedPetId!,
            serviceId: widget.service['id'],
            bookingTime: bookingDateTime,
            price: widget.service['price'],
            notes: _notesController.text.trim(),
          );
      
      if (mounted) {
        Navigator.of(context).pop(); // Закрываем bottom sheet
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка бронирования: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(tr('booking.success_title')),
          ],
        ),
        content: Text(tr('booking.success_body')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Закрываем диалог
              // Перенаправляем на вкладку записей
              context.go('/owner/bookings');
            },
            child: const Text('Отлично'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(userPetsProvider);
    final bookingState = ref.watch(bookingNotifierProvider);
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
          child: ListView(
            controller: scrollController,
            children: [
              // Полоска закрытия
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
                'Запись на прием',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.provider['business_name']} • ${widget.service['name']}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // 1. ВЫБОР ПИТОМЦА
              Text(
                tr('booking.select_pet'),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              petsAsync.when(
                data: (pets) {
                  if (pets.isEmpty) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/owner/pets'); // Перенаправляем для добавления
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Добавить питомца'),
                    );
                  }
                  
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: pets.map((pet) {
                        final isSelected = _selectedPetId == pet['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            selected: isSelected,
                            label: Text(pet['name']),
                            onSelected: (selected) {
                              setState(() {
                                _selectedPetId = selected ? pet['id'] : null;
                              });
                            },
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Ошибка: $e'),
              ),
              const SizedBox(height: 24),

              // 2. ВЫБОР ДАТЫ
              Text(
                tr('booking.select_date'),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDateSelector(theme),
              const SizedBox(height: 24),

              // 3. ВЫБОР ВРЕМЕНИ
              Text(
                tr('booking.select_time'),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((time) {
                  final isSelected = _selectedTime == time;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(time),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTime = selected ? time : null;
                      });
                    },
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 4. ЗАМЕТКИ
              Text(
                tr('booking.notes'),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Опишите симптомы или пожелания к стрижке...',
                ),
              ),
              const SizedBox(height: 32),

              // Кнопка подтверждения
              ElevatedButton(
                onPressed: _selectedPetId == null || _selectedTime == null || bookingState.isLoading
                    ? null
                    : _submitBooking,
                child: bookingState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(tr('booking.confirm_booking')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    // Генерируем следующие 7 дней
    final today = DateTime.now();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final date = today.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(_selectedDate, date);
          final dayName = index == 0 ? 'Сегодня' : index == 1 ? 'Завтра' : DateFormat('E', 'ru').format(date);
          final dayNum = DateFormat('d').format(date);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedDate = date),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white70 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayNum,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
