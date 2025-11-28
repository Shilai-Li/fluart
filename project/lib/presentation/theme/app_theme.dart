import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF00E5FF); // Cyan Neon
  static const Color _secondaryColor = Color(0xFFD500F9); // Purple Neon
  static const Color _backgroundColor = Color(
    0xFF050510,
  ); // Deep Dark Blue/Black
  static const Color _surfaceColor = Color(0xFF12122A); // Slightly lighter dark
  static const Color _errorColor = Color(0xFFFF1744);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: _primaryColor,
        secondary: _secondaryColor,
        surface: _surfaceColor,
        error: _errorColor,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // Glassmorphism Decoration
  static BoxDecoration glassDecoration({
    double opacity = 0.1,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 16,
          spreadRadius: 4,
        ),
      ],
    );
  }

  // Neon Glow Decoration
  static BoxDecoration neonDecoration({Color color = _primaryColor}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
