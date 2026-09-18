import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  void toggleTheme() {
    themeNotifier.value =
        themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    themeNotifier.value = mode;
  }
}
