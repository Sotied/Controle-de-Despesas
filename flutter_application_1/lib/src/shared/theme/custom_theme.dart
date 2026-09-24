import 'package:flutter/material.dart';

class CustomColors {
  static const Color background = Color(0xFF0B1020);
  static const Color surface = Color(0xFF141B2D);
  static const Color surfaceElevated = Color(0xFF1C2740);
  static const Color outline = Color(0xFF35415E);
  static const Color onSurface = Color(0xFFF4F7FF);
  static const Color onSurfaceMuted = Color(0xFFB7C1D9);

  static const Color primaryDarken1 = Color(0xFF315CC7);
  static const Color primaryBase = Color(0xFF5B8CFF);
  static const Color primaryLighten1 = Color(0xFF89ADFF);
  static const Color primaryLighten2 = Color(0xFF1E3E7A);
  static const Color primaryLighten3 = Color(0xFF152A51);

  static const Color secondaryDarken1 = Color(0xFF167B65);
  static const Color secondaryBase = Color(0xFF50D7A8);
  static const Color secondaryLighten1 = Color(0xFF86E8C7);
  static const Color secondaryLighten2 = Color(0xFF143F38);

  static const Color blackBase = onSurface;
  static const Color blackLighten1 = onSurfaceMuted;
  static const Color blackLighten2 = Color(0xFF8290AB);
  static const Color blackLighten3 = Color(0xFF56627C);
  static const Color blackLighten4 = surfaceElevated;

  static const Color whiteDarken1 = surface;
  static const Color whiteBase = Color(0xFFFFFFFF);

  static const Color successDarken1 = Color(0xFF167B65);
  static const Color successBase = secondaryBase;
  static const Color successLighten1 = Color(0xFF86E8C7);

  static const Color errorDarken1 = Color(0xFFFF8980);
  static const Color errorBase = Color(0xFFFFB4AB);
  static const Color errorLighten1 = Color(0xFF5D1D1A);

  static const Color warnDarken1 = Color(0xFFFFC76B);
  static const Color warnBase = Color(0xFFFFD792);
  static const Color warnLighten1 = Color(0xFF4A3817);

  static const Color infoDarken1 = Color(0xFF77B7FF);
  static const Color infoBase = primaryBase;
  static const Color infoLighten1 = Color(0xFF1D3D6D);
}

class CustomTypography {
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.25,
  );
  static const TextStyle titleRegular = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.1,
  );
  static const TextStyle chipPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const TextStyle chipSecondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const TextStyle caption2 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
}

ThemeData customTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: CustomColors.background,
    textTheme: const TextTheme(
      displaySmall: CustomTypography.display,
      headlineLarge: CustomTypography.headline,
      headlineMedium: CustomTypography.titleRegular,
      headlineSmall: CustomTypography.title,
      titleLarge: CustomTypography.title,
      titleMedium: CustomTypography.subtitle,
      titleSmall: CustomTypography.subtitle2,
      bodyLarge: CustomTypography.body1,
      bodyMedium: CustomTypography.body2,
      bodySmall: CustomTypography.caption2,
      labelLarge: CustomTypography.button,
      labelMedium: CustomTypography.chipSecondary,
      labelSmall: CustomTypography.caption2,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      toolbarHeight: 45,
      backgroundColor: CustomColors.background,
      foregroundColor: CustomColors.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: CustomColors.primaryBase,
      onPrimary: CustomColors.whiteBase,
      primaryContainer: CustomColors.primaryLighten2,
      onPrimaryContainer: CustomColors.onSurface,
      secondary: CustomColors.secondaryBase,
      onSecondary: CustomColors.background,
      surface: CustomColors.surface,
      surfaceTint: Colors.transparent,
      onSurface: CustomColors.onSurface,
      error: CustomColors.errorBase,
      onError: CustomColors.background,
      onErrorContainer: CustomColors.errorLighten1,
    ),
    cardTheme: const CardThemeData(
      color: CustomColors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: CustomColors.surface,
      indicatorColor: CustomColors.primaryLighten2,
      labelTextStyle: WidgetStatePropertyAll(CustomTypography.chipSecondary),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: CustomColors.onSurfaceMuted),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: CustomColors.surfaceElevated,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: CustomColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: CustomColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: CustomColors.primaryBase, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      childrenPadding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
      iconColor: CustomColors.onSurfaceMuted,
      collapsedIconColor: CustomColors.onSurfaceMuted,
      textColor: CustomColors.onSurface,
      collapsedTextColor: CustomColors.onSurface,
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(CustomColors.primaryLighten1),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: CustomColors.primaryLighten1, width: 1.5),
    ),
    datePickerTheme: DatePickerThemeData(
      headerForegroundColor: CustomColors.onSurface,
      headerBackgroundColor: CustomColors.surfaceElevated,
      rangePickerHeaderForegroundColor: CustomColors.onSurface,
      rangePickerHeaderBackgroundColor: CustomColors.surfaceElevated,
      rangePickerBackgroundColor: CustomColors.surface,
      backgroundColor: CustomColors.surface,
      rangePickerHeaderHeadlineStyle: CustomTypography.title,
      headerHeadlineStyle: CustomTypography.title,
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return CustomColors.primaryLighten2;
        } else if (states.contains(WidgetState.disabled)) {
          return CustomColors.blackLighten3;
        } else {
          return Colors.transparent;
        }
      }),
      dayForegroundColor: const WidgetStatePropertyAll(CustomColors.onSurface),
      rangeSelectionBackgroundColor: CustomColors.primaryLighten3,
    ),
  );
}
