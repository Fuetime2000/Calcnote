import 'package:flutter/material.dart';
import 'package:calcnote/src/features/ai/services/smart_suggestion_service.dart';

/// Panel showing smart suggestions
class SmartSuggestionsPanel extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final Function(SmartSuggestion) onSuggestionTap;

  const SmartSuggestionsPanel({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Suggestions',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.take(3).map((suggestion) {
              return _buildSuggestionChip(suggestion, theme);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(SmartSuggestion suggestion, ThemeData theme) {
    IconData icon;
    Color? color;

    switch (suggestion.type) {
      case SuggestionType.formula:
        icon = Icons.functions;
        color = Colors.blue;
        break;
      case SuggestionType.calculation:
        icon = Icons.calculate;
        color = Colors.green;
        break;
      case SuggestionType.autocomplete:
        icon = Icons.auto_awesome;
        color = Colors.purple;
        break;
      case SuggestionType.template:
        icon = Icons.description;
        color = Colors.orange;
        break;
      case SuggestionType.correction:
        icon = Icons.edit;
        color = Colors.red;
        break;
    }

    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            suggestion.description,
            style: theme.textTheme.labelSmall,
          ),
          Text(
            suggestion.text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onPressed: () => onSuggestionTap(suggestion),
    );
  }
}
