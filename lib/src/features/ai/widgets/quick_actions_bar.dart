import 'package:flutter/material.dart';
import 'package:calcnote/src/features/ai/services/smart_suggestion_service.dart';

/// Bar showing quick action buttons
class QuickActionsBar extends StatelessWidget {
  final List<QuickAction> actions;
  final Function(QuickAction) onActionTap;

  const QuickActionsBar({
    super.key,
    required this.actions,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionButton(action, theme);
        },
      ),
    );
  }

  Widget _buildActionButton(QuickAction action, ThemeData theme) {
    return OutlinedButton.icon(
      icon: Text(
        action.icon,
        style: const TextStyle(fontSize: 20),
      ),
      label: Text(action.label),
      onPressed: () => onActionTap(action),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
