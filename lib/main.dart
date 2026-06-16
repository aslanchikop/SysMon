// 🐾 Main Entry Point for Animora

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/supabase_config.dart';

void main() async {
  // Гарантируем инициализацию привязок Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем локализацию
  await EasyLocalization.ensureInitialized();
  
  // Инициализируем Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ru'),
        Locale('kk'),
      ],
      path: 'assets/translations', // Путь к файлам локализации
      fallbackLocale: const Locale('ru'),
      child: const ProviderScope(
        child: AnimoraApp(),
      ),
    ),
  );
}
