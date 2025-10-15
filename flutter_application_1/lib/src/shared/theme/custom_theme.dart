import 'package:flutter/material.dart';

class CustomColors {
  static const Color primaryDarken1 = Color(0xFF4D191D);
  static const Color primaryBase = Color(0xFF971E27);
  static const Color primaryLighten1 = Color(0xFFCD202C);
  static const Color primaryLighten2 = Color(0xFFF0BCC0);
  static const Color primaryLighten3 = Color(0xFFFAE9EA);

  static const Color secondaryDarken1 = Color(0xFF0D2D3F);
  static const Color secondaryBase = Color(0xFF0D2D3F);
  static const Color secondaryLighten1 = Color(0xFF004165);
  static const Color secondaryLighten2 = Color(0xFFB3C6D1);

  static const Color blackBase = Color(0xFF1A1A1A);
  static const Color blackLighten1 = Color(0xFF4D4D4D);
  static const Color blackLighten2 = Color(0xFF8C8C8C);
  static const Color blackLighten3 = Color(0xFFCCCCCC);
  static const Color blackLighten4 = Color(0xFFE6E6E6);

  static const Color whiteDarken1 = Color(0xFFF5F5F5);
  static const Color whiteBase = Color(0xFFFFFFFF);

  static const Color successDarken1 = Color(0xFF00583D);
  static const Color successBase = Color(0xFF107154);
  static const Color successLighten1 = Color(0xFF86DDBB);

  static const Color errorDarken1 = Color(0xFFB40000);
  static const Color errorBase = Color(0xFFE10000);
  static const Color errorLighten1 = Color(0xFFFFD3D3);

  static const Color warnDarken1 = Color(0xFFD8B500);
  static const Color warnBase = Color(0xFFF7D002);
  static const Color warnLighten1 = Color(0xFFFFFF93);

  static const Color infoDarken1 = Color(0xFF007CD6);
  static const Color infoBase = Color(0xFF2196F3);
  static const Color infoLighten1 = Color(0xFFB5FFFF);
}

class CustomTypography {
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: CustomColors.blackBase,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: CustomColors.blackBase,
  );

  static const TextStyle titleRegular = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: CustomColors.blackBase,
  );

  static const TextStyle titleRegular2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: CustomColors.blackBase,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle caption2 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle chipPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle chipSecondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
}

ThemeData customTheme() {
  return ThemeData(
    fontFamily: 'Verdana',
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      toolbarHeight: 45,
      backgroundColor: CustomColors.whiteBase,
      elevation: 1,
      shadowColor: CustomColors.blackLighten1,
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: CustomColors.primaryLighten1,
      onPrimary: CustomColors.whiteBase,
      primaryContainer: CustomColors.primaryLighten2,
      onPrimaryContainer: CustomColors.primaryDarken1,
      secondary: CustomColors.secondaryBase,
      onSecondary: CustomColors.whiteBase,
      surface: CustomColors.whiteBase,
      surfaceTint: CustomColors.whiteBase,
      onSurface: CustomColors.blackLighten1,
      error: CustomColors.errorBase,
      onError: CustomColors.whiteBase,
      onErrorContainer: CustomColors.errorLighten1,
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
      iconColor: CustomColors.blackBase,
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(CustomColors.primaryLighten1),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: CustomColors.primaryLighten1, width: 1.5),
    ),
    datePickerTheme: DatePickerThemeData(
      headerForegroundColor: CustomColors.blackBase,
      headerBackgroundColor: CustomColors.blackLighten4,
      rangePickerHeaderForegroundColor: CustomColors.blackBase,
      rangePickerHeaderBackgroundColor: CustomColors.blackLighten4,
      rangePickerBackgroundColor: CustomColors.whiteDarken1,
      backgroundColor: CustomColors.whiteDarken1,
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
      dayForegroundColor: const WidgetStatePropertyAll(CustomColors.blackBase),
      rangeSelectionBackgroundColor: CustomColors.primaryLighten3,
    ),
  );
}
