// 🐾 Modern Material 3 Design System for Animora

import 'package:flutter/material.dart';

class AppTheme {
  // Цветовая палитра
  static const Color primaryColor = Color(0xFF6C63FF); // Премиальный фиолетовый
  static const Color secondaryColor = Color(0xFFFF6B6B); // Коралловый акцент
  static const Color successColor = Color(0xFF4ECDC4); // Бирюзовый успех
  
  // Светлая тема
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: const Color(0xFFE53935),
        surface: Colors.white,
        background: const Color(0xFFF8F9FE),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: const Color(0xFF1E1E24),
        onSurface: const Color(0xFF1E1E24),
        primaryContainer: const Color(0xFFEAEAFF),
        secondaryContainer: const Color(0xFFFFECEC),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF1E1E24),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: Color(0xFF1E1E24)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xFF1E1E24)),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1E1E24)),
        titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFF1E1E24)),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF4A4A57)),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6A6A7D)),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6A6A7D)),
        floatingLabelStyle: const TextStyle(color: primaryColor),
      ),
    );
  }

  // Темная тема
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8B85FF),
        secondary: Color(0xFFFF8585),
        error: Color(0xFFEF5350),
        surface: Color(0xFF252642),
        background: Color(0xFF1A1B2E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Color(0xFFE8E8F0),
        onSurface: Color(0xFFE8E8F0),
        primaryContainer: Color(0xFF35365C),
        secondaryContainer: Color(0xFF55323C),
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1B2E),
      cardTheme: CardThemeData(
        color: const Color(0xFF252642),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D2E55), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFE8E8F0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: Color(0xFFE8E8F0)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xFFE8E8F0)),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFFE8E8F0)),
        titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFFE8E8F0)),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFFB0B0C4)),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF88889C)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B85FF),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF20213A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D2E55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D2E55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8B85FF), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF88889C)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF8B85FF)),
      ),
    );
  }
}
