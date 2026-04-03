import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - 深蓝紫渐变风格
  static const Color primary = Color(0xFF5B7FFF);
  static const Color primaryLight = Color(0xFF7B9FFF);
  static const Color primaryDark = Color(0xFF3B5FDF);

  // 背景色（暗色主题）
  static const Color bgDark = Color(0xFF0F1117);
  static const Color bgCard = Color(0xFF1A1D2E);
  static const Color bgCardLight = Color(0xFF242740);

  // 背景色（亮色主题）
  static const Color bgLight = Color(0xFFF5F6FA);
  static const Color bgCardWhite = Color(0xFFFFFFFF);

  // 状态色
  static const Color connected = Color(0xFF4CAF50);
  static const Color connectedGlow = Color(0x334CAF50);
  static const Color disconnected = Color(0xFF9E9E9E);
  static const Color connecting = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  // 延迟颜色
  static const Color latencyGood = Color(0xFF4CAF50);
  static const Color latencyMid = Color(0xFFFFC107);
  static const Color latencyBad = Color(0xFFF44336);

  // 文字色
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8FA8);
  static const Color textHint = Color(0xFF4A4F68);

  // 分割线
  static const Color divider = Color(0xFF242740);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgCard,
        background: AppColors.bgDark,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelSmall: TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textHint;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary.withOpacity(0.4);
          }
          return AppColors.bgCardLight;
        }),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.bgCardWhite,
        background: AppColors.bgLight,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1A1D2E),
        onBackground: Color(0xFF1A1D2E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLight,
        foregroundColor: Color(0xFF1A1D2E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1D2E),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.bgCardWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
