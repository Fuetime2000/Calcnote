import 'package:calcnote/src/features/ai/services/formula_detection_service.dart';

/// Service for providing smart suggestions while typing
class SmartSuggestionService {
  /// Get suggestions based on current text
  static List<SmartSuggestion> getSuggestions(String text) {
    final suggestions = <SmartSuggestion>[];
    final lowerText = text.toLowerCase();
    
    // Formula suggestions
    if (lowerText.contains('interest') && !lowerText.contains('=')) {
      suggestions.add(SmartSuggestion(
        text: 'SI = (P × R × T) / 100',
        type: SuggestionType.formula,
        description: 'Simple Interest Formula',
      ));
    }
    
    if (lowerText.contains('profit') && !lowerText.contains('=')) {
      suggestions.add(SmartSuggestion(
        text: 'Profit = SP - CP',
        type: SuggestionType.formula,
        description: 'Profit Formula',
      ));
    }
    
    if (lowerText.contains('area') && lowerText.contains('circle')) {
      suggestions.add(SmartSuggestion(
        text: 'Area = π × r²',
        type: SuggestionType.formula,
        description: 'Area of Circle',
      ));
    }
    
    if (lowerText.contains('area') && lowerText.contains('rectangle')) {
      suggestions.add(SmartSuggestion(
        text: 'Area = length × width',
        type: SuggestionType.formula,
        description: 'Area of Rectangle',
      ));
    }
    
    // Calculation corrections
    final numbers = FormulaDetectionService.extractNumbers(text);
    if (numbers.length >= 2) {
      final sum = numbers.reduce((a, b) => a + b);
      suggestions.add(SmartSuggestion(
        text: 'Sum = $sum',
        type: SuggestionType.calculation,
        description: 'Total of all numbers',
      ));
      
      final avg = sum / numbers.length;
      suggestions.add(SmartSuggestion(
        text: 'Average = ${avg.toStringAsFixed(2)}',
        type: SuggestionType.calculation,
        description: 'Average of all numbers',
      ));
    }
    
    // Auto-complete suggestions
    if (lowerText.endsWith('si')) {
      suggestions.add(SmartSuggestion(
        text: 'Simple Interest = (P × R × T) / 100',
        type: SuggestionType.autocomplete,
        description: 'Complete formula',
      ));
    }
    
    if (lowerText.endsWith('ci')) {
      suggestions.add(SmartSuggestion(
        text: 'Compound Interest = P(1 + R/100)^T - P',
        type: SuggestionType.autocomplete,
        description: 'Complete formula',
      ));
    }
    
    // Template suggestions
    if (lowerText.contains('expense') || lowerText.contains('spent')) {
      suggestions.add(SmartSuggestion(
        text: 'Item: \nAmount: ₹\nDate: ',
        type: SuggestionType.template,
        description: 'Expense Template',
      ));
    }
    
    if (lowerText.contains('todo') || lowerText.contains('task')) {
      suggestions.add(SmartSuggestion(
        text: '☐ Task 1\n☐ Task 2\n☐ Task 3',
        type: SuggestionType.template,
        description: 'Todo List Template',
      ));
    }
    
    return suggestions;
  }
  
  /// Get quick action suggestions
  static List<QuickAction> getQuickActions(String text) {
    final actions = <QuickAction>[];
    
    // If text has numbers, suggest sum/average
    final numbers = FormulaDetectionService.extractNumbers(text);
    if (numbers.length >= 2) {
      actions.add(QuickAction(
        icon: '∑',
        label: 'Sum',
        action: ActionType.calculateSum,
      ));
      
      actions.add(QuickAction(
        icon: '≈',
        label: 'Average',
        action: ActionType.calculateAverage,
      ));
    }
    
    // If text mentions formulas
    if (text.toLowerCase().contains('interest')) {
      actions.add(QuickAction(
        icon: '%',
        label: 'Calculate SI',
        action: ActionType.calculateInterest,
      ));
    }
    
    // Translation action
    if (text.isNotEmpty) {
      actions.add(QuickAction(
        icon: '🌐',
        label: 'Translate',
        action: ActionType.translate,
      ));
    }
    
    // Summary action
    if (text.split('\n').length > 5) {
      actions.add(QuickAction(
        icon: '📋',
        label: 'Summarize',
        action: ActionType.summarize,
      ));
    }
    
    return actions;
  }
  
  /// Get formula suggestions based on keywords
  static List<String> getFormulaSuggestions(String keyword) {
    final formulas = <String, String>{
      'interest': 'SI = (P × R × T) / 100',
      'profit': 'Profit = SP - CP',
      'loss': 'Loss = CP - SP',
      'discount': 'Discount = MP - SP',
      'percentage': 'Percentage = (Value / Total) × 100',
      'area': 'Area = length × width',
      'speed': 'Speed = Distance / Time',
    };
    
    final lowerKeyword = keyword.toLowerCase();
    return formulas.entries
        .where((e) => e.key.contains(lowerKeyword))
        .map((e) => e.value)
        .toList();
  }
}

/// Smart suggestion model
class SmartSuggestion {
  final String text;
  final SuggestionType type;
  final String description;
  
  SmartSuggestion({
    required this.text,
    required this.type,
    required this.description,
  });
}

/// Suggestion type enum
enum SuggestionType {
  formula,
  calculation,
  autocomplete,
  template,
  correction,
}

/// Quick action model
class QuickAction {
  final String icon;
  final String label;
  final ActionType action;
  
  QuickAction({
    required this.icon,
    required this.label,
    required this.action,
  });
}

/// Action type enum
enum ActionType {
  calculateSum,
  calculateAverage,
  calculateInterest,
  translate,
  summarize,
  formatAsList,
  addTemplate,
}
