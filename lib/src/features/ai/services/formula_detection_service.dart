import 'dart:math' as math;
import 'package:calcnote/src/core/utils/calculation_utils.dart';

/// Service for detecting and solving mathematical formulas automatically
class FormulaDetectionService {
  // Common formula patterns
  static final Map<String, String> _formulaExplanations = {
    'simple_interest': 'Simple Interest = (P × R × T) / 100',
    'compound_interest': 'Compound Interest = P(1 + R/100)^T - P',
    'profit': 'Profit = Selling Price - Cost Price',
    'loss': 'Loss = Cost Price - Selling Price',
    'profit_percent': 'Profit% = (Profit / CP) × 100',
    'loss_percent': 'Loss% = (Loss / CP) × 100',
    'discount': 'Discount = Marked Price - Selling Price',
    'discount_percent': 'Discount% = (Discount / MP) × 100',
    'area_circle': 'Area of Circle = π × r²',
    'area_rectangle': 'Area of Rectangle = length × width',
    'area_triangle': 'Area of Triangle = ½ × base × height',
    'perimeter_rectangle': 'Perimeter = 2(length + width)',
    'circumference': 'Circumference = 2πr',
    'speed': 'Speed = Distance / Time',
    'distance': 'Distance = Speed × Time',
    'time': 'Time = Distance / Speed',
    'percentage': 'Percentage = (Value / Total) × 100',
    'average': 'Average = Sum of values / Count',
  };

  /// Detect formulas in text
  static List<DetectedFormula> detectFormulas(String text) {
    final List<DetectedFormula> formulas = [];
    
    // Detect mathematical expressions
    final mathPattern = RegExp(r'(\d+\.?\d*)\s*([+\-×*/÷%^()])\s*(\d+\.?\d*)');
    final matches = mathPattern.allMatches(text);
    
    for (final match in matches) {
      final expression = match.group(0)!;
      final result = CalculationUtils.evaluateExpression(expression);
      
      if (result.isNotEmpty) {
        formulas.add(DetectedFormula(
          expression: expression,
          result: result,
          type: 'calculation',
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    // Detect formula keywords
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('interest') || lowerText.contains('si')) {
      formulas.add(DetectedFormula(
        expression: 'Simple Interest',
        result: _formulaExplanations['simple_interest']!,
        type: 'formula_explanation',
        startIndex: 0,
        endIndex: 0,
      ));
    }
    
    if (lowerText.contains('profit') || lowerText.contains('loss')) {
      formulas.add(DetectedFormula(
        expression: 'Profit/Loss',
        result: _formulaExplanations['profit']!,
        type: 'formula_explanation',
        startIndex: 0,
        endIndex: 0,
      ));
    }
    
    if (lowerText.contains('discount')) {
      formulas.add(DetectedFormula(
        expression: 'Discount',
        result: _formulaExplanations['discount']!,
        type: 'formula_explanation',
        startIndex: 0,
        endIndex: 0,
      ));
    }
    
    if (lowerText.contains('area') && lowerText.contains('circle')) {
      formulas.add(DetectedFormula(
        expression: 'Area of Circle',
        result: _formulaExplanations['area_circle']!,
        type: 'formula_explanation',
        startIndex: 0,
        endIndex: 0,
      ));
    }
    
    if (lowerText.contains('speed') || lowerText.contains('distance') || lowerText.contains('time')) {
      formulas.add(DetectedFormula(
        expression: 'Speed-Distance-Time',
        result: _formulaExplanations['speed']!,
        type: 'formula_explanation',
        startIndex: 0,
        endIndex: 0,
      ));
    }
    
    return formulas;
  }
  
  /// Get formula explanation by name
  static String? getFormulaExplanation(String formulaName) {
    return _formulaExplanations[formulaName.toLowerCase().replaceAll(' ', '_')];
  }
  
  /// Calculate simple interest
  static double calculateSimpleInterest(double principal, double rate, double time) {
    return (principal * rate * time) / 100;
  }
  
  /// Calculate compound interest
  static double calculateCompoundInterest(double principal, double rate, double time) {
    return principal * math.pow(1 + rate / 100, time) - principal;
  }
  
  /// Calculate profit percentage
  static double calculateProfitPercent(double costPrice, double sellingPrice) {
    final profit = sellingPrice - costPrice;
    return (profit / costPrice) * 100;
  }
  
  /// Calculate discount percentage
  static double calculateDiscountPercent(double markedPrice, double sellingPrice) {
    final discount = markedPrice - sellingPrice;
    return (discount / markedPrice) * 100;
  }
  
  /// Extract numbers from text
  static List<double> extractNumbers(String text) {
    final numberPattern = RegExp(r'\d+\.?\d*');
    final matches = numberPattern.allMatches(text);
    return matches.map((m) => double.tryParse(m.group(0)!) ?? 0).toList();
  }
  
  /// Calculate average of numbers in text
  static double? calculateAverage(String text) {
    final numbers = extractNumbers(text);
    if (numbers.isEmpty) return null;
    return numbers.reduce((a, b) => a + b) / numbers.length;
  }
  
  /// Calculate sum of numbers in text
  static double? calculateSum(String text) {
    final numbers = extractNumbers(text);
    if (numbers.isEmpty) return null;
    return numbers.reduce((a, b) => a + b);
  }
}

/// Model for detected formula
class DetectedFormula {
  final String expression;
  final String result;
  final String type; // 'calculation', 'formula_explanation', 'suggestion'
  final int startIndex;
  final int endIndex;
  
  DetectedFormula({
    required this.expression,
    required this.result,
    required this.type,
    required this.startIndex,
    required this.endIndex,
  });
}
