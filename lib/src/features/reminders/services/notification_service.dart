import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_model.dart';
import '../../../core/services/navigation_service.dart';
import '../../notes/models/note_model.dart';
import '../../notes/screens/note_editor_screen.dart';

/// Background notification handler (must be top-level function)
@pragma('vm:entry-point')
void _onBackgroundNotificationReceived(NotificationResponse response) async {
  // Handle background notification - mark "once" reminders as completed
  final noteId = response.payload;
  if (noteId == null || noteId.isEmpty) return;

  try {
    await Hive.initFlutter();
    final remindersBox = await Hive.openBox<ReminderModel>('reminders');
    
    final reminder = remindersBox.values.firstWhere(
      (r) => r.noteId == noteId && r.isActive && !r.isCompleted,
      orElse: () => throw Exception('No active reminder found'),
    );
    
    if (reminder.repeatType == 'none') {
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
        isNotified: true,
        isSnoozed: reminder.isSnoozed,
        snoozeUntil: reminder.snoozeUntil,
        tags: reminder.tags,
      );
      
      await remindersBox.put(reminder.id, updatedReminder);
    }
  } catch (e) {
    debugPrint('Error in background notification handler: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationReceived,
    );

    // Request permissions
    await _requestPermissions();

    _initialized = true;
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    // Android 13+ requires runtime permission
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Request notification permission
      final notificationGranted = await androidPlugin.requestNotificationsPermission();
      
      // Request exact alarm permission (Android 12+)
      final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
      
      return (notificationGranted ?? false) && (exactAlarmGranted ?? true);
    }

    // iOS permissions
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) async {
    // Get note ID from payload
    final noteId = response.payload;
    if (noteId == null || noteId.isEmpty) return;

    try {
      // Mark "once" reminders as completed
      await _handleReminderCompletion(noteId);
      
      // Open notes box and get the note
      final notesBox = await Hive.openBox<NoteModel>('notes');
      final note = notesBox.get(noteId);
      
      if (note != null) {
        // Navigate to note editor
        NavigationService().push(
          NoteEditorScreen(note: note),
        );
      }
    } catch (e) {
      debugPrint('Error opening note from notification: $e');
    }
  }
  
  /// Handle reminder completion for "once" reminders
  Future<void> _handleReminderCompletion(String noteId) async {
    try {
      // Open reminders box
      final remindersBox = await Hive.openBox<ReminderModel>('reminders');
      
      // Find reminder for this note
      final reminder = remindersBox.values.firstWhere(
        (r) => r.noteId == noteId && r.isActive && !r.isCompleted,
        orElse: () => throw Exception('No active reminder found'),
      );
      
      // If it's a "once" reminder, mark as completed
      if (reminder.repeatType == 'none') {
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
          isNotified: true,
          isSnoozed: reminder.isSnoozed,
          snoozeUntil: reminder.snoozeUntil,
          tags: reminder.tags,
        );
        
        // Save updated reminder
        await remindersBox.put(reminder.id, updatedReminder);
        debugPrint('Marked "once" reminder as completed: ${reminder.id}');
      } else {
        // For repeating reminders, schedule next occurrence
        DateTime nextReminderTime = reminder.reminderTime;
        
        switch (reminder.repeatType) {
          case 'daily':
            nextReminderTime = reminder.reminderTime.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextReminderTime = reminder.reminderTime.add(const Duration(days: 7));
            break;
          case 'monthly':
            nextReminderTime = DateTime(
              reminder.reminderTime.year,
              reminder.reminderTime.month + 1,
              reminder.reminderTime.day,
              reminder.reminderTime.hour,
              reminder.reminderTime.minute,
            );
            break;
        }
        
        final updatedReminder = ReminderModel(
          id: reminder.id,
          noteId: reminder.noteId,
          title: reminder.title,
          description: reminder.description,
          reminderTime: nextReminderTime,
          priority: reminder.priority,
          repeatType: reminder.repeatType,
          createdAt: reminder.createdAt,
          isCompleted: false,
          completedAt: reminder.completedAt,
          isNotified: true,
          isSnoozed: reminder.isSnoozed,
          snoozeUntil: reminder.snoozeUntil,
          tags: reminder.tags,
        );
        
        await remindersBox.put(reminder.id, updatedReminder);
        
        // Schedule the next notification
        await scheduleReminder(updatedReminder);
        
        debugPrint('Scheduled next occurrence for repeating reminder: ${reminder.id} at $nextReminderTime');
      }
    } catch (e) {
      debugPrint('Error handling reminder completion: $e');
    }
  }

  /// Schedule a reminder notification
  Future<void> scheduleReminder(ReminderModel reminder) async {
    if (!_initialized) await initialize();

    final notificationId = reminder.id.hashCode;
    
    // Cancel existing notification if any
    await _notifications.cancel(notificationId);

    // Don't schedule if completed or in the past
    if (reminder.isCompleted || reminder.reminderTime.isBefore(DateTime.now())) {
      return;
    }

    // Notification details
    final androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Task and note reminders',
      importance: _getImportance(reminder.priority),
      priority: _getPriority(reminder.priority),
      icon: '@mipmap/ic_launcher',
      color: _getColor(reminder.priority),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule notification
    await _notifications.zonedSchedule(
      notificationId,
      reminder.title,
      reminder.description ?? 'Tap to view',
      tz.TZDateTime.from(reminder.reminderTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.noteId,
    );
  }

  /// Cancel a reminder notification
  Future<void> cancelReminder(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await _notifications.cancel(notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// Show immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Task and note reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Helper: Get importance from priority
  Importance _getImportance(String priority) {
    switch (priority) {
      case 'high':
        return Importance.max;
      case 'medium':
        return Importance.high;
      case 'low':
        return Importance.defaultImportance;
      default:
        return Importance.high;
    }
  }

  /// Helper: Get priority from priority string
  Priority _getPriority(String priority) {
    switch (priority) {
      case 'high':
        return Priority.max;
      case 'medium':
        return Priority.high;
      case 'low':
        return Priority.defaultPriority;
      default:
        return Priority.high;
    }
  }

  /// Helper: Get color from priority
  Color? _getColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF5252); // Red
      case 'medium':
        return const Color(0xFFFFA726); // Orange
      case 'low':
        return const Color(0xFF66BB6A); // Green
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  /// Check if exact alarm permission is granted
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Check if exact alarms are allowed
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    
    return true; // iOS or other platforms
  }

  /// Open app settings for exact alarm permission
  Future<void> openAlarmSettings() async {
    try {
      // Try to open exact alarm settings directly (Android 12+)
      const platform = MethodChannel('com.calcnote.app/settings');
      try {
        await platform.invokeMethod('openExactAlarmSettings');
      } catch (e) {
        // Fallback to general app settings
        debugPrint('Could not open exact alarm settings, opening app settings: $e');
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('Error opening settings: $e');
    }
  }

  /// Reschedule all active reminders (useful after app restart)
  Future<void> rescheduleAllReminders(List<ReminderModel> reminders) async {
    for (final reminder in reminders) {
      if (reminder.isActive && !reminder.isCompleted) {
        await scheduleReminder(reminder);
      }
    }
  }
}
