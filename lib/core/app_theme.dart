import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF1A6FDB);
  static const Color primaryLight = Color(0xFFE8F1FC);
  static const Color accent = Color(0xFF0F9E75);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFE53E3E);

  // Category colors
  static const Map<String, Color> categoryColors = {
    'cafe': Color(0xFF8B5CF6),
    'fotokopi': Color(0xFF3B82F6),
    'atm': Color(0xFF10B981),
    'minimarket': Color(0xFFF59E0B),
    'kos': Color(0xFFEF4444),
    'layanan kesehatan': Color(0xFF06B6D4),
  };

  // Category icons
  static const Map<String, IconData> categoryIcons = {
    'cafe': Icons.local_cafe,
    'fotokopi': Icons.print,
    'atm': Icons.atm,
    'minimarket': Icons.store,
    'kos': Icons.home,
    'layanan kesehatan': Icons.local_hospital,
  };

  static Color getCategoryColor(String categoryName) {
    return categoryColors[categoryName.toLowerCase()] ??
        const Color(0xFF6B7280);
  }

  static IconData getCategoryIcon(String categoryName) {
    return categoryIcons[categoryName.toLowerCase()] ?? Icons.place;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1A1A2E),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF9CA3AF),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF9CA3AF),
          fontSize: 14,
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
    );
  }
}