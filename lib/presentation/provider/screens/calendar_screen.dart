// 🐾 Provider Calendar Scheduler Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/data_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('tabs.calendar')),
      ),
      body: Column(
        children: [
          // 1. СЕЛЕКТОР ДАТЫ (Горизонтальный календарь на 14 дней)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _buildDateSelector(theme),
          ),
          
          const Divider(height: 1),

          // 2. СПИСОК ЗАПИСЕЙ НА ВЫБРАННЫЙ ДЕНЬ
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                // Фильтруем записи только для выбранного дня и со статусом confirmed
                final dayBookings = bookings.where((b) {
                  final bTime = DateTime.parse(b['booking_time']);
                  return DateUtils.isSameDay(bTime, _selectedDate) && b['status'] == 'confirmed';
                }).toList();

                if (dayBookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет записей на этот день',
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Все подтвержденные клиенты появятся здесь.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Сортируем по времени
                dayBookings.sort((a, b) => a['booking_time'].compareTo(b['booking_time']));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayBookings.length,
                  itemBuilder: (context, index) {
                    final booking = dayBookings[index];
                    final client = booking['profiles'] ?? {};
                    final pet = booking['pets'] ?? {};
                    final service = booking['services'] ?? {};
                    final bookingTime = DateTime.parse(booking['booking_time']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Колонка времени
                            Container(
                              width: 70,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('HH:mm').format(bookingTime),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Детали визита
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${pet['name']} (${pet['breed'] ?? "без породы"})',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Услуга: ${service['name']}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Хозяин: ${client['full_name']} • ${client['phone'] ?? ""}',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    // Генерируем 14 дней начиная с сегодняшнего
    final today = DateTime.now();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(14, (index) {
          final date = today.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(_selectedDate, date);
          
          final dayName = index == 0 
              ? 'Сегодня' 
              : index == 1 
                  ? 'Завтра' 
                  : DateFormat('E', 'ru').format(date);
          final dayNum = DateFormat('d').format(date);

          return Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: InkWell(
              onTap: () => setState(() => _selectedDate = date),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 75,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white70 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayNum,
                      style: TextStyle(
                        fontSize: 20,
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
