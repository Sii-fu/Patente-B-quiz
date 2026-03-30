import 'package:flutter/material.dart';

class AppTheme {
  // Private Brand Colors based on the Logo
  // Bangladesh Flag Green (Bottle Green)
  static const Color primaryGreen = Color(0xFF006A4E); 
  // Bangladesh/Italy Red
  static const Color primaryRed = Color(0xFFF42A41);
  // Italian White (Standard White)
  static const Color brandWhite = Color(0xFFFFFFFF);
  // Dark Background for Dark Mode
  static const Color darkBackground = Color(0xFF121212);
  
  // Semantic Colors (public for direct access when needed)
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF42A41);
  
  // Legacy colors for backward compatibility
  static const Color primaryBrandGreen = Color(0xFF006A4E);
  static const Color primaryBrandBlue = Color(0xFF006A4E); // Map to green
  static const Color darkGrey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFFF8F8F8);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006A4E), Color(0xFF008f6b)],
  );

  // -------------------------
  // LIGHT THEME
  // -------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        onPrimary: brandWhite,
        secondary: primaryRed,
        onSecondary: brandWhite,
        surface: brandWhite,
        onSurface: Colors.black87,
        error: primaryRed,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: brandWhite,
        elevation: 0,
        centerTitle: true,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: brandWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: brandWhite,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
        ),
      ),

      // Input/Form Decoration Theme (Important for "Patente" forms)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: primaryGreen),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // -------------------------
  // DARK THEME
  // -------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        // In dark mode, we make the green slightly lighter for contrast
        primary: const Color(0xFF008f6b), 
        onPrimary: brandWhite,
        secondary: const Color(0xFFff6b7e), // Softer red for dark mode
        onSecondary: Colors.black,
        surface: darkBackground,
        onSurface: brandWhite,
        error: const Color(0xFFcf6679),
      ),

      // App Bar Theme (Dark)
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: brandWhite,
        elevation: 0,
        centerTitle: true,
      ),
      
      // Card Theme (Dark)
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button Themes (Dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008f6b), // Lighter green
          foregroundColor: brandWhite,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text Button Theme (Dark)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF008f6b),
        ),
      ),

      // Input Decoration (Dark)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF008f6b), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF008f6b)),
      ),
      
      // Snackbar Theme (Dark)
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}