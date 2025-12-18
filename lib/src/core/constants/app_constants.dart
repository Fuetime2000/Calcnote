class AppConstants {
  // App
  static const String appName = 'CalcNote';
  
  // Storage
  static const String notesBox = 'notes_box';
  static const String settingsBox = 'settings_box';
  
  // Settings keys
  static const String themeMode = 'theme_mode';
  static const String isBiometricEnabled = 'is_biometric_enabled';
  
  // Default values
  static const String defaultNoteTitle = 'Untitled Note';
  
  // Calculation patterns
  static final RegExp calculationPattern = RegExp(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^\n]+)');
  static final RegExp mathExpressionPattern = RegExp(r'([-+*/%^()\d\s.]+)');
  
  // Math functions
  static const List<String> mathFunctions = [
    'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
    'sqrt', 'log', 'ln', 'exp', 'abs', 'round',
    'ceil', 'floor', 'pi', 'e'
  ];
  
  // App version
  static const String version = '1.0.0';
}
