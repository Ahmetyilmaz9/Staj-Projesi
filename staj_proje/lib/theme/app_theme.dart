import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEEF0F6);
  static const ink = Color(0xFF12141C);
  static const inkMuted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const primary = Color(0xFF4F46E5);
  static const primarySoft = Color(0xFFEEF0FF);
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFE7F9F1);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3E2);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFDECEC);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFEAF2FE);
  static const navBg = Color(0xFF12141C);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(primary: AppColors.primary, surface: AppColors.surface),
      scaffoldBackgroundColor: AppColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.line)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.inkMuted),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.line,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.12),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
        bodyMedium: TextStyle(color: AppColors.ink),
        labelSmall: TextStyle(color: AppColors.inkMuted, letterSpacing: 0.4),
      ),
    );
  }

  static Color statusColor(String durum) {
    switch (durum) {
      case 'KRITIK':
        return AppColors.danger;
      case 'UYARI':
        return AppColors.warning;
      case 'FAZLA':
        return AppColors.info;
      case 'NORMAL':
        return AppColors.success;
      default:
        return AppColors.inkMuted;
    }
  }

  static Color statusSoft(String durum) {
    switch (durum) {
      case 'KRITIK':
        return AppColors.dangerSoft;
      case 'UYARI':
        return AppColors.warningSoft;
      case 'FAZLA':
        return AppColors.infoSoft;
      case 'NORMAL':
        return AppColors.successSoft;
      default:
        return AppColors.surfaceAlt;
    }
  }
}
