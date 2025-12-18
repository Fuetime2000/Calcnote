import 'package:hive/hive.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 3)
class ReminderModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String noteId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String? description;

  @HiveField(4)
  DateTime reminderTime;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  bool isNotified;

  @HiveField(7)
  String priority; // 'low', 'medium', 'high'

  @HiveField(8)
  String? repeatType; // 'none', 'daily', 'weekly', 'monthly'

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  bool isSnoozed;

  @HiveField(12)
  DateTime? snoozeUntil;

  @HiveField(13)
  List<String> tags;

  ReminderModel({
    required this.id,
    required this.noteId,
    required this.title,
    this.description,
    required this.reminderTime,
    this.isCompleted = false,
    this.isNotified = false,
    this.priority = 'medium',
    this.repeatType = 'none',
    required this.createdAt,
    this.completedAt,
    this.isSnoozed = false,
    this.snoozeUntil,
    this.tags = const [],
  });

  // Create a copy with updated fields
  ReminderModel copyWith({
    String? id,
    String? noteId,
    String? title,
    String? description,
    DateTime? reminderTime,
    bool? isCompleted,
    bool? isNotified,
    String? priority,
    String? repeatType,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isSnoozed,
    DateTime? snoozeUntil,
    List<String>? tags,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isNotified: isNotified ?? this.isNotified,
      priority: priority ?? this.priority,
      repeatType: repeatType ?? this.repeatType,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isSnoozed: isSnoozed ?? this.isSnoozed,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      tags: tags ?? this.tags,
    );
  }

  // Check if reminder is overdue
  bool get isOverdue {
    if (isCompleted || isSnoozed) return false;
    return DateTime.now().isAfter(reminderTime);
  }

  // Check if reminder is due soon (within 1 hour)
  bool get isDueSoon {
    if (isCompleted || isSnoozed) return false;
    final now = DateTime.now();
    final diff = reminderTime.difference(now);
    return diff.isNegative == false && diff.inMinutes <= 60;
  }

  // Check if reminder is active (not completed and not snoozed)
  bool get isActive {
    if (isCompleted) return false;
    if (isSnoozed && snoozeUntil != null) {
      return DateTime.now().isAfter(snoozeUntil!);
    }
    return true;
  }

  // Get formatted time remaining
  String get timeRemaining {
    if (isCompleted) return 'Completed';
    if (isSnoozed && snoozeUntil != null) {
      return 'Snoozed until ${_formatDateTime(snoozeUntil!)}';
    }

    final now = DateTime.now();
    final diff = reminderTime.difference(now);

    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inDays > 0) return '${absDiff.inDays}d overdue';
      if (absDiff.inHours > 0) return '${absDiff.inHours}h overdue';
      if (absDiff.inMinutes > 0) return '${absDiff.inMinutes}m overdue';
      return 'Overdue';
    }

    if (diff.inDays > 0) return 'In ${diff.inDays}d';
    if (diff.inHours > 0) return 'In ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'In ${diff.inMinutes}m';
    return 'Now';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'noteId': noteId,
      'title': title,
      'description': description,
      'reminderTime': reminderTime.toIso8601String(),
      'isCompleted': isCompleted,
      'isNotified': isNotified,
      'priority': priority,
      'repeatType': repeatType,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isSnoozed': isSnoozed,
      'snoozeUntil': snoozeUntil?.toIso8601String(),
      'tags': tags,
    };
  }

  // Create from JSON
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      reminderTime: DateTime.parse(json['reminderTime'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isNotified: json['isNotified'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      repeatType: json['repeatType'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isSnoozed: json['isSnoozed'] as bool? ?? false,
      snoozeUntil: json['snoozeUntil'] != null
          ? DateTime.parse(json['snoozeUntil'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  String toString() {
    return 'ReminderModel(id: $id, title: $title, reminderTime: $reminderTime, isCompleted: $isCompleted)';
  }
}

// Register Hive adapter
void registerReminderHiveAdapter() {
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ReminderModelAdapter());
  }
}
