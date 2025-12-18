import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:calcnote/src/core/utils/calculation_utils.dart';

// Hive Type ID for NoteModel
const int noteModelTypeId = 0;

// Manual Hive Adapter for NoteModel
class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = noteModelTypeId;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return NoteModel(
      id: fields[0] as String? ?? const Uuid().v4(),
      title: fields[1] as String? ?? '',
      content: fields[2] as String? ?? '',
      createdAt: fields[3] as DateTime? ?? DateTime.now(),
      updatedAt: fields[4] as DateTime? ?? DateTime.now(),
      tags: (fields[5] as List?)?.cast<String>() ?? [],
      isPinned: fields[6] as bool? ?? false,
      isArchived: fields[7] as bool? ?? false,
      isLocked: fields[8] as bool? ?? false,
      category: fields[9] as String?,
      summary: fields[10] as String?,
      themeColor: fields[11] as String?,
      themeType: fields[12] as String?,
      hasPdfAttachments: fields[13] as bool? ?? false,
      images: (fields[14] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(15) // Number of fields
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.content)
      ..writeByte(3)..write(obj.createdAt)
      ..writeByte(4)..write(obj.updatedAt)
      ..writeByte(5)..write(obj.tags)
      ..writeByte(6)..write(obj.isPinned)
      ..writeByte(7)..write(obj.isArchived)
      ..writeByte(8)..write(obj.isLocked)
      ..writeByte(9)..write(obj.category)
      ..writeByte(10)..write(obj.summary)
      ..writeByte(11)..write(obj.themeColor)
      ..writeByte(12)..write(obj.themeType)
      ..writeByte(13)..write(obj.hasPdfAttachments)
      ..writeByte(14)..write(obj.images);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

@HiveType(typeId: noteModelTypeId)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String content;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  DateTime updatedAt;
  
  @HiveField(5)
  List<String> tags;
  
  @HiveField(6, defaultValue: false)
  bool isPinned;
  
  @HiveField(7, defaultValue: false)
  bool isArchived;
  
  @HiveField(8, defaultValue: false)
  bool isLocked;
  
  @HiveField(9)
  String? category; // AI-detected category
  
  @HiveField(10)
  String? summary; // AI-generated summary
  
  @HiveField(11)
  String? themeColor; // Custom theme color (hex string)
  
  @HiveField(12)
  String? themeType; // Theme type: default, study, work, personal, time-based
  
  @HiveField(13, defaultValue: false)
  bool hasPdfAttachments; // Whether note has PDF attachments
  
  @HiveField(14)
  List<String>? images; // List of image file paths
  
  NoteModel({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    this.isPinned = false,
    this.isArchived = false,
    this.isLocked = false,
    this.category,
    this.summary,
    this.themeColor,
    this.themeType,
    this.hasPdfAttachments = false,
    this.images,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];
  
  // Create a copy with method for immutability
  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
    String? category,
    String? summary,
    String? themeColor,
    String? themeType,
    bool? hasPdfAttachments,
    List<String>? images,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? List.from(this.tags),
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isLocked: isLocked ?? this.isLocked,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      themeColor: themeColor ?? this.themeColor,
      themeType: themeType ?? this.themeType,
      hasPdfAttachments: hasPdfAttachments ?? this.hasPdfAttachments,
      images: images ?? (this.images != null ? List.from(this.images!) : null),
    );
  }
  
  // Convert to map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isLocked': isLocked,
      'category': category,
      'summary': summary,
      'themeColor': themeColor,
      'themeType': themeType,
      'hasPdfAttachments': hasPdfAttachments,
      'images': images,
    };
  }
  
  // Create from map for JSON deserialization
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      isPinned: map['isPinned'] ?? false,
      isArchived: map['isArchived'] ?? false,
      isLocked: map['isLocked'] ?? false,
      category: map['category'],
      summary: map['summary'],
      themeColor: map['themeColor'],
      themeType: map['themeType'],
      hasPdfAttachments: map['hasPdfAttachments'] ?? false,
      images: map['images'] != null ? List<String>.from(map['images']) : null,
    );
  }
  
  // Get a preview of the note content (first line or first 50 characters)
  String get preview {
    if (content.isEmpty) return '';
    String firstLine = content.split('\n').first.trim();
    if (firstLine.length > 50) {
      return '${firstLine.substring(0, 47)}...';
    }
    return firstLine;
  }
  
  // Check if the note has calculations
  bool get hasCalculations {
    return content.contains(RegExp(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^\n]+)'));
  }
  
  // Get all calculation results as a map
  Map<String, String> get calculations {
    return CalculationUtils.extractCalculations(content);
  }
  
  // Get the total of all calculations
  String? get total {
    final calcs = calculations.values.toList();
    if (calcs.isEmpty) return null;
    
    try {
      double sum = 0;
      for (String val in calcs) {
        sum += double.tryParse(val) ?? 0;
      }
      return sum.toStringAsFixed(sum % 1 == 0 ? 0 : 2);
    } catch (e) {
      return null;
    }
  }
}

// Register the adapter
void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(noteModelTypeId)) {
    Hive.registerAdapter(NoteModelAdapter());
  }
}
