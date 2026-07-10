import 'package:flutter/material.dart';
import 'app_state.dart';

class AppColors {
  // Backgrounds
  static Color get bg          => appState.isDarkMode ? const Color(0xFF0E0B1E) : const Color(0xFFF0F0F5);
  static Color get surface     => appState.isDarkMode ? const Color(0xFF1A1535) : const Color(0xFFFFFFFF);
  static Color get surface2    => appState.isDarkMode ? const Color(0xFF231D45) : const Color(0xFFF7F7FA);
  static Color get card        => appState.isDarkMode ? const Color(0xFF2A2350) : const Color(0xFFFFFFFF);

  // Accents
  static Color get gold        => const Color(0xFFF5A623);
  static Color get goldLight   => const Color(0xFFFFCC66);
  static Color get goldDark    => const Color(0xFFB87A10);
  static Color get purple      => const Color(0xFF7B5EA7);
  static Color get purpleLight => const Color(0xFF9B7EC8);
  static Color get purpleDark  => const Color(0xFF4A3575);

  // Status
  static Color get success     => const Color(0xFF2ECC71);
  static Color get error       => const Color(0xFFE74C3C);
  static Color get warning     => const Color(0xFFF39C12);

  // Text
  static Color get white       => appState.isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1A1535);
  static Color get grey        => const Color(0xFF8A85A8);
  static Color get greyLight   => appState.isDarkMode ? const Color(0xFFB8B4D0) : const Color(0xFF6B658A);

  // Border
  static Color get border      => appState.isDarkMode ? const Color(0xFF3A3260) : const Color(0xFFE0E0E5);
  static Color get borderLight => appState.isDarkMode ? const Color(0xFF4A4275) : const Color(0xFFD0D0D5);
}
