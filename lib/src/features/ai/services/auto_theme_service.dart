import 'package:flutter/material.dart';

/// Service for automatically toggling dark mode based on time or ambient light
class AutoThemeService {
  /// Determine if dark mode should be enabled based on time
  static bool shouldUseDarkMode({DateTime? currentTime}) {
    final time = currentTime ?? DateTime.now();
    final hour = time.hour;
    
    // Dark mode from 6 PM (18:00) to 6 AM (06:00)
    return hour >= 18 || hour < 6;
  }
  
  /// Get theme mode based on time
  static ThemeMode getThemeModeByTime({DateTime? currentTime}) {
    return shouldUseDarkMode(currentTime: currentTime) 
        ? ThemeMode.dark 
        : ThemeMode.light;
  }
  
  /// Get brightness based on time
  static Brightness getBrightnessByTime({DateTime? currentTime}) {
    return shouldUseDarkMode(currentTime: currentTime)
        ? Brightness.dark
        : Brightness.light;
  }
  
  /// Get time-based theme description
  static String getThemeDescription({DateTime? currentTime}) {
    final time = currentTime ?? DateTime.now();
    final hour = time.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning! ☀️ Light mode active';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon! 🌤️ Light mode active';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening! 🌆 Dark mode active';
    } else {
      return 'Good Night! 🌙 Dark mode active';
    }
  }
  
  /// Calculate next theme change time
  static DateTime getNextThemeChangeTime({DateTime? currentTime}) {
    final time = currentTime ?? DateTime.now();
    final hour = time.hour;
    
    if (hour < 6) {
      // Next change at 6 AM today
      return DateTime(time.year, time.month, time.day, 6, 0);
    } else if (hour < 18) {
      // Next change at 6 PM today
      return DateTime(time.year, time.month, time.day, 18, 0);
    } else {
      // Next change at 6 AM tomorrow
      final tomorrow = time.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0);
    }
  }
  
  /// Get theme transition message
  static String getTransitionMessage(bool isDarkMode) {
    if (isDarkMode) {
      return 'Switched to Dark Mode 🌙';
    } else {
      return 'Switched to Light Mode ☀️';
    }
  }
}

/// Theme preference model
class ThemePreference {
  final ThemeMode mode;
  final bool autoSwitch;
  final int darkModeStartHour;
  final int darkModeEndHour;
  
  const ThemePreference({
    this.mode = ThemeMode.system,
    this.autoSwitch = true,
    this.darkModeStartHour = 18,
    this.darkModeEndHour = 6,
  });
  
  ThemePreference copyWith({
    ThemeMode? mode,
    bool? autoSwitch,
    int? darkModeStartHour,
    int? darkModeEndHour,
  }) {
    return ThemePreference(
      mode: mode ?? this.mode,
      autoSwitch: autoSwitch ?? this.autoSwitch,
      darkModeStartHour: darkModeStartHour ?? this.darkModeStartHour,
      darkModeEndHour: darkModeEndHour ?? this.darkModeEndHour,
    );
  }
}
