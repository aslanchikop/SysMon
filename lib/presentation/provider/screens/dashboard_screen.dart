// 🐾 Provider CRM Dashboard Screen for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/data_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('provider_dashboard.welcome')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(userBookingsProvider),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          // Разделяем записи на "Новые заявки" (pending) и "Остальные на сегодня"
          final pendingRequests = bookings.where((b) => b['status'] == 'pending').toList();
          final activeBookings = bookings.where((b) => b['status'] == 'confirmed').toList();
          
          // Вычисляем суммарный недельный доход (подтвержденные и завершенные)
          final double totalRevenue = bookings
              .where((b) => b['status'] == 'confirmed' || b['status'] == 'completed')
              .map((b) => (b['price'] as num).toDouble())
              .fold(0, (sum, price) => sum + price);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. СЕКЦИЯ СТАТИСТИКИ (Карточки)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: tr('provider_dashboard.stats_revenue'),
                        value: '${totalRevenue.toInt()} ₸',
                        icon: Icons.monetization_on_rounded,
                        color: Colors.green,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: tr('provider_dashboard.stats_bookings'),
                        value: '${bookings.length}',
                        icon: Icons.calendar_month_rounded,
                        color: theme.colorScheme.primary,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 2. НОВЫЕ ЗАЯВКИ (Ожидающие подтверждения)
                Text(
                  tr('provider_dashboard.new_requests'),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (pendingRequests.isEmpty)
                  _buildEmptyStateCard(tr('provider_dashboard.no_requests'), theme)
                else
                  ...pendingRequests.map((booking) => _buildRequestCard(context, booking, ref, theme)),
                
                const SizedBox(height: 32),

                // 3. ПОДТВЕРЖДЕННЫЕ ЗАПИСИ (Расписание)
                Text(
                  'Активные записи',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (activeBookings.isEmpty)
                  _buildEmptyStateCard('Нет активных записей', theme)
                else
                  ...activeBookings.map((booking) => _buildBookingCard(context, booking, ref, theme)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка загрузки дашборда: $err')),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(String message, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> booking, WidgetRef ref, ThemeData theme) {
    final client = booking['profiles'] ?? {};
    final pet = booking['pets'] ?? {};
    final service = booking['services'] ?? {};
    final bookingTime = DateTime.parse(booking['booking_time']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.primary.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text(
                  client['full_name'] ?? 'Клиент',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('HH:mm (dd.MM)').format(bookingTime),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Услуга: ${service['name']}',
              style: theme.textTheme.bodyLarge,
            ),
            Text(
              'Питомец: ${pet['name']} (${pet['breed'] ?? "без породы"})',
              style: theme.textTheme.bodyMedium,
            ),
            if (booking['notes'] != null && booking['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Заметка: "${booking['notes']}"',
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _updateStatus(context, ref, booking['id'], 'cancelled'),
                    child: Text(tr('provider_dashboard.decline')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _updateStatus(context, ref, booking['id'], 'confirmed'),
                    child: Text(tr('provider_dashboard.accept')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking, WidgetRef ref, ThemeData theme) {
    final client = booking['profiles'] ?? {};
    final pet = booking['pets'] ?? {};
    final service = booking['services'] ?? {};
    final bookingTime = DateTime.parse(booking['booking_time']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Text(
              '${pet['name']} • ${client['full_name'] ?? "Владелец"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('HH:mm').format(bookingTime),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Услуга: ${service['name']}'),
            Text('Телефон: ${client['phone'] ?? "не указан"}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) => _updateStatus(context, ref, booking['id'], val),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'completed',
              child: Text('Завершить'),
            ),
            const PopupMenuItem(
              value: 'cancelled',
              child: Text('Отменить', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String bookingId, String newStatus) async {
    try {
      await ref.read(bookingNotifierProvider.notifier).updateBookingStatus(bookingId, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'confirmed'
                  ? 'Запись подтверждена'
                  : newStatus == 'completed'
                      ? 'Запись успешно завершена'
                      : 'Запись отменена',
            ),
            backgroundColor: newStatus == 'confirmed' || newStatus == 'completed' ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления статуса: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
