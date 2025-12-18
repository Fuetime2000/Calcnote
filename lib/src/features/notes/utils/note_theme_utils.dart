import 'package:flutter/material.dart';

/// Note theme utility class for managing note colors and themes
class NoteThemeUtils {
  // Predefined theme colors
  static const Map<String, NoteTheme> themes = {
    'default': NoteTheme(
      name: 'Default',
      backgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF000000),
      icon: Icons.note,
    ),
    'study': NoteTheme(
      name: 'Study',
      backgroundColor: Color(0xFFE3F2FD),
      textColor: Color(0xFF1565C0),
      icon: Icons.school,
    ),
    'work': NoteTheme(
      name: 'Work',
      backgroundColor: Color(0xFFFFF3E0),
      textColor: Color(0xFFE65100),
      icon: Icons.work,
    ),
    'personal': NoteTheme(
      name: 'Personal',
      backgroundColor: Color(0xFFF3E5F5),
      textColor: Color(0xFF6A1B9A),
      icon: Icons.person,
    ),
    'important': NoteTheme(
      name: 'Important',
      backgroundColor: Color(0xFFFFEBEE),
      textColor: Color(0xFFC62828),
      icon: Icons.priority_high,
    ),
    'idea': NoteTheme(
      name: 'Idea',
      backgroundColor: Color(0xFFFFF9C4),
      textColor: Color(0xFFF57F17),
      icon: Icons.lightbulb,
    ),
    'finance': NoteTheme(
      name: 'Finance',
      backgroundColor: Color(0xFFE8F5E9),
      textColor: Color(0xFF2E7D32),
      icon: Icons.attach_money,
    ),
    'health': NoteTheme(
      name: 'Health',
      backgroundColor: Color(0xFFE0F2F1),
      textColor: Color(0xFF00695C),
      icon: Icons.favorite,
    ),
    'travel': NoteTheme(
      name: 'Travel',
      backgroundColor: Color(0xFFE1F5FE),
      textColor: Color(0xFF0277BD),
      icon: Icons.flight,
    ),
    'food': NoteTheme(
      name: 'Food',
      backgroundColor: Color(0xFFFCE4EC),
      textColor: Color(0xFFC2185B),
      icon: Icons.restaurant,
    ),
  };

  /// Get theme based on time of day
  static NoteTheme getTimeBasedTheme() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      // Morning - Bright and energetic
      return const NoteTheme(
        name: 'Morning',
        backgroundColor: Color(0xFFFFF8E1),
        textColor: Color(0xFFF57F17),
        icon: Icons.wb_sunny,
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon - Warm and focused
      return const NoteTheme(
        name: 'Afternoon',
        backgroundColor: Color(0xFFFFE0B2),
        textColor: Color(0xFFE65100),
        icon: Icons.wb_cloudy,
      );
    } else if (hour >= 17 && hour < 21) {
      // Evening - Calm and relaxing
      return const NoteTheme(
        name: 'Evening',
        backgroundColor: Color(0xFFD1C4E9),
        textColor: Color(0xFF512DA8),
        icon: Icons.wb_twilight,
      );
    } else {
      // Night - Dark and soothing
      return const NoteTheme(
        name: 'Night',
        backgroundColor: Color(0xFFB39DDB),
        textColor: Color(0xFF311B92),
        icon: Icons.nightlight_round,
      );
    }
  }

  /// Get theme by category
  static NoteTheme? getThemeByCategory(String? category) {
    if (category == null) return null;
    
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('study') || lowerCategory.contains('education')) {
      return themes['study'];
    } else if (lowerCategory.contains('work') || lowerCategory.contains('task')) {
      return themes['work'];
    } else if (lowerCategory.contains('expense') || lowerCategory.contains('finance')) {
      return themes['finance'];
    } else if (lowerCategory.contains('health') || lowerCategory.contains('fitness')) {
      return themes['health'];
    } else if (lowerCategory.contains('travel')) {
      return themes['travel'];
    } else if (lowerCategory.contains('food') || lowerCategory.contains('recipe')) {
      return themes['food'];
    } else if (lowerCategory.contains('idea')) {
      return themes['idea'];
    } else if (lowerCategory.contains('personal')) {
      return themes['personal'];
    }
    
    return null;
  }

  /// Parse color from hex string
  static Color? parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      return null;
    }
    
    return null;
  }

  /// Convert color to hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

/// Note theme model
class NoteTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const NoteTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}
