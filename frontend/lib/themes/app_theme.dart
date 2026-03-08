import 'package:flutter/material.dart';

class AppThemes {
  static const Color kPrimaryBlueLight = Color(0xFF3A84E0); // Light mode blue
  static const Color kPrimaryBlueDark = Color(0xFF2266B6); // Dark mode blue

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: kPrimaryBlueLight,
    scaffoldBackgroundColor: const Color(0xFFF4F8FC),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryBlueLight,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: Colors.black54),
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: kPrimaryBlueLight,
      secondary: kPrimaryBlueLight,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: kPrimaryBlueDark,
    scaffoldBackgroundColor: const Color(0xFF141B25),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryBlueDark,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: Colors.white70),
    cardColor: Color(0xFF222C3A),
    colorScheme: ColorScheme.fromSwatch(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
    ).copyWith(
      primary: kPrimaryBlueDark,
      secondary: kPrimaryBlueDark,
    ),
  );
}


