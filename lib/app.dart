// 🐾 Root App Widget setup for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class AnimoraApp extends ConsumerWidget {
  const AnimoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Animora',
      
      // Мультиязычность
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      
      // Темы оформления
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Автоматическое переключение светлая/темная
      
      // Навигация через GoRouter
      routerConfig: router,
      
      // Отключаем плашку "Debug"
      debugShowCheckedModeBanner: false,
    );
  }
}
