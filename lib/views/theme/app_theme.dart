import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: const ColorScheme.dark().copyWith(
        primary: Colors.teal,
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTextStyles {
  static TextStyle get title => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 14,
      );
}

