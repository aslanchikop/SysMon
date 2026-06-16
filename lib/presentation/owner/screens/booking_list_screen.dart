// 🐾 Booking List Screen for Pet Owners in Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/data_providers.dart';

class BookingListScreen extends ConsumerWidget {
  const BookingListScreen({super.key});

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getStatusTranslation(String status) {
    switch (status) {
      case 'pending':
        return tr('booking.status_pending');
      case 'confirmed':
        return tr('booking.status_confirmed');
      case 'completed':
        return tr('booking.status_completed');
      case 'cancelled':
        return tr('booking.status_cancelled');
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('tabs.bookings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(userBookingsProvider),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'У вас нет активных записей',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Запишите питомца на прием на главном экране',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final provider = booking['providers'] ?? {};
              final pet = booking['pets'] ?? {};
              final service = booking['services'] ?? {};
              final bookingTime = DateTime.parse(booking['booking_time']);
              
              final status = booking['status'] ?? 'pending';
              final statusColor = _getStatusColor(status, theme);
              final statusText = _getStatusTranslation(status);

              final isClinic = provider['type'] == 'vet_clinic';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Верхняя строчка: Провайдер + Статус
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Expanded(
                            child: Text(
                              provider['business_name'] ?? 'Заведение',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Адрес
                      Text(
                        provider['address'] ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                      const Divider(height: 24),
                      
                      // Услуга и Питомец
                      Row(
                        children: [
                          Icon(
                            isClinic ? Icons.local_hospital_rounded : Icons.content_cut_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${service['name'] ?? "Услуга"} для ${pet['name'] ?? "питомца"}',
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Время и Цена
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: Colors.grey, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd.MM.yyyy в HH:mm', 'ru').format(bookingTime),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${booking['price']} ₸',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      // Пожелания / Заметки (если есть)
                      if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? Colors.grey.shade50
                                : const Color(0xFF20213A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Пожелания: ${booking['notes']}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка загрузки записей: $err')),
      ),
    );
  }
}
