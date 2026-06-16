// 🐾 Supabase Data Providers for Animora

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 1. СПИСОК ВСЕХ КЛИНИК И САЛОНОВ
final providersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  final response = await supabase
      .from('providers')
      .select()
      .order('rating', ascending: false);
      
  return List<Map<String, dynamic>>.from(response);
});

// 2. УСЛУГИ КОНКРЕТНОГО ПРОВАЙДЕРА
final providerServicesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  final response = await supabase
      .from('services')
      .select()
      .eq('provider_id', providerId)
      .eq('active', true);
      
  return List<Map<String, dynamic>>.from(response);
});

// 3. ПИТОМЦЫ ТЕКУЩЕГО ПОЛЬЗОВАТЕЛЯ
final userPetsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  
  if (userId == null) return [];
  
  final supabase = ref.watch(supabaseClientProvider);
  
  final response = await supabase
      .from('pets')
      .select()
      .eq('owner_id', userId)
      .order('created_at', ascending: false);
      
  return List<Map<String, dynamic>>.from(response);
});

// 4. ЗАПИСИ (БРОНИРОВАНИЯ) ПОЛЬЗОВАТЕЛЯ (Владельца или Исполнителя)
final userBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  final role = authState.role;
  
  if (userId == null) return [];
  
  final supabase = ref.watch(supabaseClientProvider);
  
  if (role == 'provider') {
    // Исполнитель видит записи к своим точкам
    final providerResponse = await supabase
        .from('providers')
        .select('id')
        .eq('profile_id', userId)
        .maybeSingle();
        
    if (providerResponse == null) return [];
    final providerId = providerResponse['id'];

    final response = await supabase
        .from('bookings')
        .select('*, profiles(full_name, phone), pets(name, breed, species), services(name)')
        .eq('provider_id', providerId)
        .order('booking_time', ascending: true);
        
    return List<Map<String, dynamic>>.from(response);
  } else {
    // Владелец видит свои записи
    final response = await supabase
        .from('bookings')
        .select('*, providers(business_name, address, type), pets(name, species), services(name, price)')
        .eq('owner_id', userId)
        .order('booking_time', ascending: true);
        
    return List<Map<String, dynamic>>.from(response);
  }
});

// 5. УПРАВЛЕНИЕ ЗАПИСЯМИ (Создание и обновление статуса)
class BookingNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  BookingNotifier(this._supabase, this._ref) : super(const AsyncValue.data(null));

  // Создать бронирование
  Future<void> createBooking({
    required String providerId,
    required String petId,
    required String serviceId,
    required DateTime bookingTime,
    required int price,
    String? notes,
  }) async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null) throw Exception('Пользователь не авторизован');
    
    state = const AsyncValue.loading();
    try {
      await _supabase.from('bookings').insert({
        'owner_id': userId,
        'provider_id': providerId,
        'pet_id': petId,
        'service_id': serviceId,
        'booking_time': bookingTime.toIso8601String(),
        'price': price,
        'notes': notes,
        'status': 'pending',
      });
      state = const AsyncValue.data(null);
      // Обновляем список записей
      _ref.invalidate(userBookingsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Обновить статус бронирования (для провайдера)
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      await _supabase
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);
      state = const AsyncValue.data(null);
      _ref.invalidate(userBookingsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final bookingNotifierProvider = StateNotifierProvider<BookingNotifier, AsyncValue<void>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BookingNotifier(supabase, ref);
});

// 6. ДОБАВЛЕНИЕ ПИТОМЦА
class PetNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  PetNotifier(this._supabase, this._ref) : super(const AsyncValue.data(null));

  Future<void> addPet({
    required String name,
    required String species,
    String? breed,
    DateTime? birthDate,
    double? weight,
  }) async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null) throw Exception('Пользователь не авторизован');

    state = const AsyncValue.loading();
    try {
      await _supabase.from('pets').insert({
        'owner_id': userId,
        'name': name,
        'species': species,
        'breed': breed,
        'birth_date': birthDate?.toIso8601String().split('T')[0],
        'weight': weight,
      });
      state = const AsyncValue.data(null);
      _ref.invalidate(userPetsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final petNotifierProvider = StateNotifierProvider<PetNotifier, AsyncValue<void>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PetNotifier(supabase, ref);
});
