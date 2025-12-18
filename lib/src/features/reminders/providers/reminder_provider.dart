import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  static const String _boxName = 'reminders';
  Box<ReminderModel>? _reminderBox;
  List<ReminderModel> _reminders = [];

  List<ReminderModel> get reminders => _reminders;

  /// Initialize the provider and load reminders
  Future<void> initialize() async {
    try {
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ReminderModelAdapter());
      }

      // Open box
      _reminderBox = await Hive.openBox<ReminderModel>(_boxName);
      
      // Load reminders
      await loadReminders();
      
      // Listen to box changes to auto-reload when reminders are updated
      _reminderBox!.listenable().addListener(() {
        loadReminders();
      });
      
      // Initialize notification service
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Error initializing ReminderProvider: $e');
    }
  }

  /// Load all reminders from storage
  Future<void> loadReminders() async {
    try {
      if (_reminderBox != null) {
        _reminders = _reminderBox!.values.toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }
  }

  /// Add a new reminder
  Future<void> addReminder(ReminderModel reminder) async {
    try {
      await _reminderBox?.put(reminder.id, reminder);
      _reminders.add(reminder);
      notifyListeners();
      
      // Schedule notification
      await NotificationService().scheduleReminder(reminder);
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      rethrow;
    }
  }

  /// Update an existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _reminderBox?.put(reminder.id, reminder);
      
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
        notifyListeners();
      }
      
      // Reschedule notification
      await NotificationService().scheduleReminder(reminder);
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      rethrow;
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _reminderBox?.delete(reminderId);
      _reminders.removeWhere((r) => r.id == reminderId);
      notifyListeners();
      
      // Cancel notification
      await NotificationService().cancelReminder(reminderId);
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
    }
  }

  /// Get reminders for a specific note
  List<ReminderModel> getRemindersForNote(String noteId) {
    return _reminders.where((r) => r.noteId == noteId).toList();
  }

  /// Get active reminder for a note (not completed, not past)
  ReminderModel? getActiveReminderForNote(String noteId) {
    try {
      return _reminders.firstWhere(
        (r) => r.noteId == noteId && 
               r.isActive && 
               !r.isCompleted &&
               r.reminderTime.isAfter(DateTime.now()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a note has an active reminder
  bool hasActiveReminder(String noteId) {
    return getActiveReminderForNote(noteId) != null;
  }

  /// Mark reminder as completed
  Future<void> completeReminder(String reminderId) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == reminderId);
      final updatedReminder = ReminderModel(
        id: reminder.id,
        noteId: reminder.noteId,
        title: reminder.title,
        description: reminder.description,
        reminderTime: reminder.reminderTime,
        priority: reminder.priority,
        repeatType: reminder.repeatType,
        createdAt: reminder.createdAt,
        isCompleted: true,
        completedAt: DateTime.now(),
        isNotified: reminder.isNotified,
        isSnoozed: reminder.isSnoozed,
        snoozeUntil: reminder.snoozeUntil,
        tags: reminder.tags,
      );
      
      await updateReminder(updatedReminder);
    } catch (e) {
      debugPrint('Error completing reminder: $e');
    }
  }

  /// Get all active reminders (not completed, not past)
  List<ReminderModel> get activeReminders {
    final now = DateTime.now();
    return _reminders.where((r) => 
      r.isActive && 
      !r.isCompleted && 
      r.reminderTime.isAfter(now)
    ).toList();
  }

  /// Get upcoming reminders (next 24 hours)
  List<ReminderModel> get upcomingReminders {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));
    return _reminders.where((r) => 
      r.isActive && 
      !r.isCompleted && 
      r.reminderTime.isAfter(now) &&
      r.reminderTime.isBefore(tomorrow)
    ).toList();
  }

  /// Get overdue reminders
  List<ReminderModel> get overdueReminders {
    final now = DateTime.now();
    return _reminders.where((r) => 
      r.isActive && 
      !r.isCompleted && 
      r.reminderTime.isBefore(now)
    ).toList();
  }

  /// Reschedule all active reminders (useful after app restart)
  Future<void> rescheduleAllReminders() async {
    try {
      await NotificationService().rescheduleAllReminders(activeReminders);
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }

  @override
  void dispose() {
    _reminderBox?.close();
    super.dispose();
  }
}
