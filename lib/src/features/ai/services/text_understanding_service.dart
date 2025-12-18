/// Service for understanding text content and categorizing notes
class TextUnderstandingService {
  /// Analyze text and determine its category
  static NoteCategory analyzeText(String text) {
    final lowerText = text.toLowerCase();
    
    // Math-related keywords
    if (_containsAny(lowerText, [
      'calculate', 'sum', 'total', 'add', 'subtract', 'multiply', 'divide',
      'equation', 'formula', 'math', 'algebra', '+', '-', '×', '÷', '=',
      'interest', 'profit', 'loss', 'discount', 'percentage'
    ])) {
      return NoteCategory.math;
    }
    
    // Expense-related keywords
    if (_containsAny(lowerText, [
      'expense', 'spent', 'paid', 'cost', 'price', 'buy', 'bought',
      'shopping', 'bill', 'payment', 'money', 'rupees', '₹', '\$',
      'salary', 'income', 'budget'
    ])) {
      return NoteCategory.expense;
    }
    
    // Study-related keywords
    if (_containsAny(lowerText, [
      'study', 'learn', 'exam', 'test', 'homework', 'assignment',
      'chapter', 'lesson', 'notes', 'revision', 'practice',
      'subject', 'course', 'class', 'lecture'
    ])) {
      return NoteCategory.study;
    }
    
    // Reminder-related keywords
    if (_containsAny(lowerText, [
      'remind', 'remember', 'todo', 'task', 'deadline', 'due',
      'appointment', 'meeting', 'call', 'visit', 'don\'t forget'
    ])) {
      return NoteCategory.reminder;
    }
    
    // Work-related keywords
    if (_containsAny(lowerText, [
      'work', 'project', 'client', 'meeting', 'presentation',
      'report', 'deadline', 'team', 'manager', 'office'
    ])) {
      return NoteCategory.work;
    }
    
    // Personal/Idea keywords
    if (_containsAny(lowerText, [
      'idea', 'thought', 'plan', 'goal', 'dream', 'wish',
      'personal', 'diary', 'journal'
    ])) {
      return NoteCategory.idea;
    }
    
    // Default to general
    return NoteCategory.general;
  }
  
  /// Extract intent from text
  static NoteIntent extractIntent(String text) {
    final lowerText = text.toLowerCase();
    
    if (_containsAny(lowerText, ['calculate', 'compute', 'solve', 'find', 'what is'])) {
      return NoteIntent.calculation;
    }
    
    if (_containsAny(lowerText, ['remind', 'remember', 'don\'t forget'])) {
      return NoteIntent.reminder;
    }
    
    if (_containsAny(lowerText, ['list', 'items', 'things to'])) {
      return NoteIntent.list;
    }
    
    if (_containsAny(lowerText, ['idea', 'thought', 'maybe'])) {
      return NoteIntent.idea;
    }
    
    return NoteIntent.note;
  }
  
  /// Extract key information from text
  static Map<String, dynamic> extractKeyInfo(String text) {
    final info = <String, dynamic>{};
    
    // Extract numbers
    final numberPattern = RegExp(r'\d+\.?\d*');
    final numbers = numberPattern.allMatches(text)
        .map((m) => double.tryParse(m.group(0)!) ?? 0)
        .toList();
    
    if (numbers.isNotEmpty) {
      info['numbers'] = numbers;
      info['sum'] = numbers.reduce((a, b) => a + b);
      info['average'] = info['sum'] / numbers.length;
      info['max'] = numbers.reduce((a, b) => a > b ? a : b);
      info['min'] = numbers.reduce((a, b) => a < b ? a : b);
    }
    
    // Extract dates (simple pattern)
    final datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    final dates = datePattern.allMatches(text).map((m) => m.group(0)!).toList();
    if (dates.isNotEmpty) {
      info['dates'] = dates;
    }
    
    // Extract currency amounts
    final currencyPattern = RegExp(r'[₹\$]\s*\d+\.?\d*');
    final amounts = currencyPattern.allMatches(text).map((m) => m.group(0)!).toList();
    if (amounts.isNotEmpty) {
      info['amounts'] = amounts;
    }
    
    return info;
  }
  
  /// Generate smart suggestions based on text
  static List<String> generateSuggestions(String text) {
    final suggestions = <String>[];
    final lowerText = text.toLowerCase();
    
    // If text contains numbers, suggest calculations
    final numbers = RegExp(r'\d+\.?\d*').allMatches(text);
    if (numbers.length >= 2) {
      suggestions.add('Calculate sum of all numbers');
      suggestions.add('Calculate average');
    }
    
    // If text mentions interest
    if (lowerText.contains('interest')) {
      suggestions.add('Calculate Simple Interest');
      suggestions.add('Calculate Compound Interest');
    }
    
    // If text mentions profit/loss
    if (lowerText.contains('profit') || lowerText.contains('loss')) {
      suggestions.add('Calculate Profit/Loss %');
    }
    
    // If text mentions discount
    if (lowerText.contains('discount')) {
      suggestions.add('Calculate Discount %');
    }
    
    // If text is about expenses
    if (_containsAny(lowerText, ['expense', 'spent', 'paid', 'cost'])) {
      suggestions.add('Tag as Expense');
      suggestions.add('Add to Budget Tracker');
    }
    
    return suggestions;
  }
  
  /// Check if text contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// Summarize text (extract key points)
  static String summarizeText(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) return '';
    if (lines.length <= 3) return text;
    
    // Extract first line and lines with numbers/formulas
    final summary = <String>[];
    
    // Add first line
    summary.add(lines.first);
    
    // Add lines with calculations or important info
    for (final line in lines.skip(1)) {
      if (line.contains('=') || 
          line.contains('total') || 
          line.contains('sum') ||
          RegExp(r'\d+').hasMatch(line)) {
        summary.add(line);
      }
    }
    
    return summary.take(5).join('\n');
  }
}

/// Note category enum
enum NoteCategory {
  general,
  math,
  expense,
  study,
  reminder,
  work,
  idea,
}

/// Note intent enum
enum NoteIntent {
  note,
  calculation,
  reminder,
  list,
  idea,
}

/// Extension for category display
extension NoteCategoryExtension on NoteCategory {
  String get displayName {
    switch (this) {
      case NoteCategory.general:
        return 'General';
      case NoteCategory.math:
        return 'Math';
      case NoteCategory.expense:
        return 'Expense';
      case NoteCategory.study:
        return 'Study';
      case NoteCategory.reminder:
        return 'Reminder';
      case NoteCategory.work:
        return 'Work';
      case NoteCategory.idea:
        return 'Idea';
    }
  }
  
  String get emoji {
    switch (this) {
      case NoteCategory.general:
        return '📝';
      case NoteCategory.math:
        return '🔢';
      case NoteCategory.expense:
        return '💰';
      case NoteCategory.study:
        return '📚';
      case NoteCategory.reminder:
        return '⏰';
      case NoteCategory.work:
        return '💼';
      case NoteCategory.idea:
        return '💡';
    }
  }
}
