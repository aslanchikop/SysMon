// 🐾 GoRouter setup for Animora with role-based routing

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

// Импорт экранов (создадим их позже)
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/auth/screens/role_selection_screen.dart';
import '../../presentation/owner/navigation/owner_tab_scaffold.dart';
import '../../presentation/owner/screens/home_screen.dart';
import '../../presentation/owner/screens/search_screen.dart';
import '../../presentation/owner/screens/pet_list_screen.dart';
import '../../presentation/owner/screens/booking_list_screen.dart';
import '../../presentation/owner/screens/owner_profile_screen.dart';
import '../../presentation/provider/navigation/provider_tab_scaffold.dart';
import '../../presentation/provider/screens/dashboard_screen.dart';
import '../../presentation/provider/screens/services_screen.dart';
import '../../presentation/provider/screens/provider_profile_screen.dart';
import '../../presentation/provider/screens/calendar_screen.dart';

// Экран загрузки для инициализации
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Слушатель изменений состояния авторизации для GoRouter
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) {
      final isInitialized = authState.isInitialized;
      final isAuthenticated = authState.isAuthenticated;
      final role = authState.role;

      // Ждем завершения проверки авторизации при старте приложения
      if (!isInitialized) {
        return null; // GoRouter останется на текущем месте (или покажет splash)
      }

      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      // Если пользователь не вошел в систему
      if (!isAuthenticated) {
        if (isGoingToLogin || isGoingToRegister) {
          return null; // разрешаем доступ к экранам входа/регистрации
        }
        return '/login'; // перенаправляем на логин
      }

      // Пользователь вошел, но у него нет роли
      if (role == null || role.isEmpty) {
        if (state.matchedLocation == '/role-selection') {
          return null;
        }
        return '/role-selection';
      }

      // Перенаправляем с экранов логина, если пользователь уже авторизован
      if (isGoingToLogin || isGoingToRegister || state.matchedLocation == '/role-selection' || state.matchedLocation == '/') {
        return role == 'provider' ? '/provider' : '/owner';
      }

      // Проверка безопасности: не давать владельцу заходить на маршруты провайдера и наоборот
      final isGoingToProvider = state.matchedLocation.startsWith('/provider');
      final isGoingToOwner = state.matchedLocation.startsWith('/owner');

      if (role == 'owner' && isGoingToProvider) {
        return '/owner';
      }
      if (role == 'provider' && isGoingToOwner) {
        return '/provider';
      }

      return null; // Нет перенаправления
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      
      // МАРШРУТЫ ДЛЯ ВЛАДЕЛЬЦА (С навигационной панелью ShellRoute)
      ShellRoute(
        builder: (context, state, child) {
          return OwnerTabScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/owner',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/owner/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/owner/pets',
            builder: (context, state) => const PetListScreen(),
          ),
          GoRoute(
            path: '/owner/bookings',
            builder: (context, state) => const BookingListScreen(),
          ),
          GoRoute(
            path: '/owner/profile',
            builder: (context, state) => const OwnerProfileScreen(),
          ),
        ],
      ),

      // МАРШРУТЫ ДЛЯ КЛИНИКИ/ГРУМИНГА (ShellRoute для Провайдера)
      ShellRoute(
        builder: (context, state, child) {
          return ProviderTabScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/provider',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/provider/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/provider/services',
            builder: (context, state) => const ServicesScreen(),
          ),
          GoRoute(
            path: '/provider/profile',
            builder: (context, state) => const ProviderProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
