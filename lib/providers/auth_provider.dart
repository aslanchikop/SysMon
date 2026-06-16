// 🐾 Auth state management using Supabase and Riverpod

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Модель состояния аутентификации
class AuthState {
  final User? user;
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final bool isInitialized;

  AuthState({
    this.user,
    this.profile,
    this.isLoading = true,
    this.isInitialized = false,
  });

  AuthState copyWith({
    User? user,
    Map<String, dynamic>? profile,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get isAuthenticated => user != null;
  String? get role => profile?['role'];
  String? get fullName => profile?['full_name'];
  String? get phone => profile?['phone'];
}

// Нотификатор аутентификации
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _client = Supabase.instance.client;

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    // Подписываемся на изменения состояния авторизации Supabase
    _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;
      
      if (session?.user != null) {
        // Пользователь вошел, загружаем его профиль
        final profile = await _fetchProfile(session!.user.id);
        state = AuthState(
          user: session.user,
          profile: profile,
          isLoading: false,
          isInitialized: true,
        );
      } else {
        // Пользователь вышел
        state = AuthState(
          user: null,
          profile: null,
          isLoading: false,
          isInitialized: true,
        );
      }
    });

    // Первоначальная проверка сессии при старте
    final initialUser = _client.auth.currentUser;
    if (initialUser != null) {
      final profile = await _fetchProfile(initialUser.id);
      state = AuthState(
        user: initialUser,
        profile: profile,
        isLoading: false,
        isInitialized: true,
      );
    } else {
      state = AuthState(
        user: null,
        profile: null,
        isLoading: false,
        isInitialized: true,
      );
    }
  }

  // Загрузка профиля из Supabase базы
  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      print('Ошибка при загрузке профиля: $e');
      return null;
    }
  }

  // Вход по Email/Паролю (для простоты тестирования демо)
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Регистрация по Email/Паролю
  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true);
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Обновление роли пользователя (для экрана выбора роли)
  Future<void> updateRole(String role) async {
    final userId = state.user?.id;
    if (userId == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      await _client.from('profiles').update({'role': role}).eq('id', userId);
      final updatedProfile = await _fetchProfile(userId);
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Выход из аккаунта
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _client.auth.signOut();
  }
}

// Провайдер для использования в UI
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
