import 'package:math_expressions/math_expressions.dart';
import 'package:calcnote/src/core/constants/app_constants.dart';

class CalculationUtils {
  /// Validates if the expression is safe to evaluate
  static bool _isValidExpression(String expression) {
    if (expression.isEmpty) return false;
    
    // Check for potentially dangerous patterns
    final dangerousPatterns = [
      RegExp(r'\b(import|dart:|dart\w*\.|file:|http:|https:)')
    ];
    
    for (var pattern in dangerousPatterns) {
      if (pattern.hasMatch(expression.toLowerCase())) {
        return false;
      }
    }
    
    return true;
  }

  /// Preprocesses the expression string before evaluation
  static String _preprocessExpression(String expression) {
    // Replace common math symbols
    String expr = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('^', '^')
        .replaceAll('π', 'pi')
        .replaceAll('e', 'e')
        .replaceAll('√', 'sqrt');
    
    // Add multiplication signs where needed (e.g., 2(3+4) -> 2*(3+4))
    expr = expr.replaceAllMapped(
      RegExp(r'(\d+)(?=\s*\()'),
      (match) => '${match.group(1)}*'
    );
    
    return expr;
  }

  /// Evaluates a mathematical expression and returns the result
  static String evaluateExpression(String expression) {
    try {
      if (!_isValidExpression(expression)) {
        return '';
      }
      
      String expr = _preprocessExpression(expression);
      
      // Create a parser and context
      Parser p = Parser();
      ContextModel cm = ContextModel();
      
      // Parse the expression
      Expression exp = p.parse(expr);
      
      // Evaluate the expression
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      // Handle special cases
      if (eval.isInfinite || eval.isNaN) {
        return '';
      }
      
      // Format the result
      if (eval % 1 == 0) {
        return eval.toInt().toString();
      } else {
        // Show up to 10 decimal places
        String result = eval.toStringAsFixed(10);
        // Remove trailing zeros and decimal point if not needed
        result = result.replaceAll(RegExp(r'\.?0+$'), '');
        return result;
      }
    } catch (e) {
      print('Error evaluating expression: $e');
      return '';
    }
  }

  /// Extracts all calculations from a text and returns the processed text with results
  static String processTextWithCalculations(String text) {
    if (text.isEmpty) return text;

    // Split the text into lines
    List<String> lines = text.split('\n');
    List<String> processedLines = [];

    for (String line in lines) {
      // Skip empty lines or whitespace-only lines
      if (line.trim().isEmpty) {
        processedLines.add(line);
        continue;
      }

      // Check if the line contains a calculation (e.g., "Total = 5 + 3")
      if (AppConstants.calculationPattern.hasMatch(line)) {
        RegExpMatch? match = AppConstants.calculationPattern.firstMatch(line);
        if (match != null && match.groupCount >= 2) {
          String variable = match.group(1)!.trim();
          String expression = match.group(2)!.trim();
          
          // Only process if it looks like a math expression
          if (isMathExpression(expression)) {
            // Evaluate the expression
            String result = evaluateExpression(expression);
            
            if (result.isNotEmpty) {
              // Add the original line with the result
              processedLines.add('$line = $result');
              continue;
            }
          }
        }
      } else if (isMathExpression(line)) {
        // If the whole line is a math expression, evaluate it
        String result = evaluateExpression(line);
        if (result.isNotEmpty) {
          processedLines.add('$line = $result');
          continue;
        }
      }
      
      // If no calculation was processed, add the original line
      processedLines.add(line);
    }

    return processedLines.join('\n');
  }

  /// Extracts all calculations from text and returns a map of variable names to their values
  static Map<String, String> extractCalculations(String text) {
    Map<String, String> calculations = {};
    
    if (text.isEmpty) return calculations;

    // Find all matches of the calculation pattern
    Iterable<RegExpMatch> matches = AppConstants.calculationPattern.allMatches(text);
    
    for (RegExpMatch match in matches) {
      if (match.groupCount >= 2) {
        String variable = match.group(1)!.trim();
        String expression = match.group(2)!.trim();
        
        // Evaluate the expression
        String result = evaluateExpression(expression);
        
        if (result.isNotEmpty) {
          calculations[variable] = result;
        }
      }
    }
    
    return calculations;
  }
  
  /// Checks if a line contains a mathematical expression
  static bool isMathExpression(String text) {
    if (text.trim().isEmpty) return false;
    
    // Check for common math operators or functions
    bool hasMathContent = text.contains(RegExp(r'[+\-*/%^=()]')) ||
                         AppConstants.mathFunctions.any((fn) => text.contains(fn)) ||
                         text.contains(RegExp(r'[π√e]'));
    
    if (!hasMathContent) return false;
    
    // Check for at least one number or a valid variable name
    bool hasNumbersOrVars = text.contains(RegExp(r'\d')) ||
                           text.contains(RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b'));
    
    // Check for balanced parentheses
    int openParens = '('.allMatches(text).length;
    int closeParens = ')'.allMatches(text).length;
    
    return hasNumbersOrVars && openParens == closeParens;
  }
}
