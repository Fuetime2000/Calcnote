import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calcnote/src/features/notes/models/note_model.dart';
import 'package:calcnote/src/core/utils/text_highlight_utils.dart';
import 'package:calcnote/src/features/notes/utils/note_theme_utils.dart';
import 'package:calcnote/src/features/reminders/providers/reminder_provider.dart';
import 'package:calcnote/src/features/reminders/widgets/reminder_dialog.dart';
import 'package:intl/intl.dart';

class NoteListItem extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onPinPressed;
  final VoidCallback onArchivePressed;
  final VoidCallback onDeletePressed;
  final String? searchQuery;
  
  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    required this.onPinPressed,
    required this.onArchivePressed,
    required this.onDeletePressed,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    
    // Get note theme color
    Color? noteColor;
    if (note.themeType == 'time-based') {
      noteColor = NoteThemeUtils.getTimeBasedTheme().backgroundColor;
    } else if (note.themeColor != null) {
      noteColor = NoteThemeUtils.parseColor(note.themeColor);
    } else if (note.themeType != null) {
      final noteTheme = NoteThemeUtils.themes[note.themeType];
      if (noteTheme != null) {
        noteColor = noteTheme.backgroundColor;
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      color: noteColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and pin button
              Row(
                children: [
                  // Lock icon if note is locked
                  if (note.isLocked) ...[
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: HighlightedText(
                      text: note.title.isNotEmpty ? note.title : 'Untitled Note',
                      query: searchQuery,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: note.isPinned ? theme.colorScheme.primary : null,
                    ),
                    onPressed: onPinPressed,
                    tooltip: note.isPinned ? 'Unpin' : 'Pin',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              // Preview text
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                HighlightedText(
                  text: note.preview,
                  query: searchQuery,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                  maxLines: 2,
                ),
              ],
              
              // Tags
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: note.tags.map((tag) {
                    return Chip(
                      label: Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              
              // Footer with date and actions
              const SizedBox(height: 8.0),
              Row(
                children: [
                  // Last updated time (flexible to prevent overflow)
                  Flexible(
                    child: Text(
                      dateFormat.format(note.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  
                  // Reminder indicator with priority
                  Consumer<ReminderProvider>(
                    builder: (context, reminderProvider, child) {
                      final activeReminder = reminderProvider.getActiveReminderForNote(note.id);
                      if (activeReminder != null) {
                        Color priorityColor;
                        switch (activeReminder.priority) {
                          case 'high':
                            priorityColor = Colors.red;
                            break;
                          case 'low':
                            priorityColor = Colors.green;
                            break;
                          default:
                            priorityColor = Colors.orange;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ReminderDialog(
                                  noteId: note.id,
                                  noteTitle: note.title.isEmpty ? 'Untitled Note' : note.title,
                                  existingReminder: activeReminder,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: priorityColor, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.alarm,
                                    size: 14,
                                    color: priorityColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activeReminder.priority.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: priorityColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // PDF indicator
                  if (note.hasPdfAttachments) ...[
                    const SizedBox(width: 8.0),
                    Icon(
                      Icons.picture_as_pdf,
                      size: 16,
                      color: Colors.red[700],
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Actions (with minimum constraints to prevent overflow)
                  IconButton(
                    icon: Icon(
                      note.isArchived ? Icons.unarchive : Icons.archive_outlined,
                      size: 20,
                      color: theme.hintColor,
                    ),
                    onPressed: onArchivePressed,
                    tooltip: note.isArchived ? 'Unarchive' : 'Archive',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  
                  const SizedBox(width: 4.0),
                  
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: onDeletePressed,
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
