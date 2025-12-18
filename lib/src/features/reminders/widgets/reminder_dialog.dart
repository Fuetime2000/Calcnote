import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../providers/reminder_provider.dart';

class ReminderDialog extends StatefulWidget {
  final String noteId;
  final String noteTitle;
  final ReminderModel? existingReminder;

  const ReminderDialog({
    Key? key,
    required this.noteId,
    required this.noteTitle,
    this.existingReminder,
  }) : super(key: key);

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _priority = 'medium';
  String _repeatType = 'none';
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    if (widget.existingReminder != null) {
      _selectedDate = widget.existingReminder!.reminderTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingReminder!.reminderTime);
      _priority = widget.existingReminder!.priority;
      _repeatType = widget.existingReminder!.repeatType ?? 'none';
      _descriptionController.text = widget.existingReminder!.description ?? '';
    } else {
      final now = DateTime.now();
      _selectedDate = now.add(const Duration(hours: 1));
      _selectedTime = TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveReminder() async {
    try {
      // Check if exact alarm permission is granted
      final canSchedule = await NotificationService().canScheduleExactAlarms();
      
      if (!canSchedule) {
        // Show dialog to open settings
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }

      final reminder = ReminderModel(
        id: widget.existingReminder?.id ?? const Uuid().v4(),
        noteId: widget.noteId,
        title: widget.noteTitle,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        reminderTime: _selectedDate,
        priority: _priority,
        repeatType: _repeatType,
        createdAt: widget.existingReminder?.createdAt ?? DateTime.now(),
        isCompleted: widget.existingReminder?.isCompleted ?? false,
        isNotified: false,
      );

      // Save to provider (which also schedules notification)
      final reminderProvider = context.read<ReminderProvider>();
      
      if (widget.existingReminder != null) {
        // Update existing reminder
        await reminderProvider.updateReminder(reminder);
      } else {
        // Add new reminder
        await reminderProvider.addReminder(reminder);
      }

      if (mounted) {
        Navigator.of(context).pop(reminder);
        
        final isEditing = widget.existingReminder != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing 
                ? 'Reminder updated for ${_formatDateTime(_selectedDate)}'
                : 'Reminder set for ${_formatDateTime(_selectedDate)}'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error setting reminder';
        
        // Check if it's a permission error
        if (e.toString().contains('exact alarm') || e.toString().contains('SCHEDULE_EXACT_ALARM')) {
          errorMessage = 'Please enable "Alarms & reminders" permission in Settings → Apps → CalcNote → Permissions';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: e.toString().contains('exact alarm')
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () async {
                      await NotificationService().openAlarmSettings();
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm_off, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text('Permission Required'),
            ),
          ],
        ),
        content: const Text(
          'CalcNote needs permission to schedule exact alarms for reminders.\n\n'
          'Steps:\n'
          '1. Tap "Open Settings" below\n'
          '2. Enable "Allow setting alarms and reminders"\n'
          '3. Press back to return to app\n'
          '4. Try setting reminder again\n\n'
          'Note: The setting might be called:\n'
          '• "Alarms & reminders"\n'
          '• "Set alarms"\n'
          '• "Schedule exact alarms"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService().openAlarmSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.alarm_add, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.existingReminder != null ? 'Edit Reminder' : 'Set Reminder',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Note title
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.noteTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Date picker
                Text('Date', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time picker
                Text('Time', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: theme.textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Priority
                Text('Priority', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPriorityChip('high', 'High'),
                    _buildPriorityChip('medium', 'Medium'),
                    _buildPriorityChip('low', 'Low'),
                  ],
                ),
                const SizedBox(height: 16),

                // Repeat
                Text('Repeat', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRepeatChip('none', 'Once'),
                    _buildRepeatChip('daily', 'Daily'),
                    _buildRepeatChip('weekly', 'Weekly'),
                    _buildRepeatChip('monthly', 'Monthly'),
                  ],
                ),
                const SizedBox(height: 16),

                // Description (optional)
                Text('Note (Optional)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Add a note for this reminder...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Action buttons
                Wrap(
                  alignment: widget.existingReminder != null 
                      ? WrapAlignment.spaceBetween 
                      : WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Delete button (only when editing)
                    if (widget.existingReminder != null)
                      TextButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Reminder'),
                              content: const Text('Are you sure you want to delete this reminder?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true && mounted) {
                            // Delete from provider (which also cancels notification)
                            final reminderProvider = context.read<ReminderProvider>();
                            await reminderProvider.deleteReminder(widget.existingReminder!.id);
                            
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reminder deleted'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    
                    // Right side buttons
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveReminder,
                      icon: const Icon(Icons.alarm, size: 20),
                      label: Text(widget.existingReminder != null ? 'Update' : 'Set'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _priority == value;
    final color = _getPriorityColor(value);
    
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(value), size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _priority = value;
        });
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildRepeatChip(String value, String label) {
    final isSelected = _repeatType == value;
    
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _repeatType = value;
        });
      },
    );
  }
}
