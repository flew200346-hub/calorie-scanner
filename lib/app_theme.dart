import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF6C5CE7); // โทนหลัก (ม่วงคลีน)

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,

      // พื้นหลังทั้งแอป
      scaffoldBackgroundColor: const Color(0xFFF7F4FB),

      // AppBar โปร่งใส + ตัวอักษรอ่านง่าย
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),

      // Card (ทุกหน้าจะดูเป็นชุดเดียวกันทันที)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // TextField / Dropdown สวยเหมือนกันหมด
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),

      // ปุ่มหลัก
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // ปุ่มรอง
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // Icon / Progress ใช้สีหลักอัตโนมัติ
      iconTheme: IconThemeData(color: cs.primary),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
      ),

      // Chip ให้เข้าชุด
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        selectedColor: cs.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: Colors.white,
      ),

      // BottomNavigation ให้ดูแพงขึ้น
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.8),
        thickness: 1,
      ),
    );
  }
}
