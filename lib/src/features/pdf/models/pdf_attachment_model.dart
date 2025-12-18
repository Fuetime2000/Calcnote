import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// Hive Type ID for PdfAttachmentModel
const int pdfAttachmentModelTypeId = 1;

// Manual Hive Adapter for PdfAttachmentModel
class PdfAttachmentModelAdapter extends TypeAdapter<PdfAttachmentModel> {
  @override
  final int typeId = pdfAttachmentModelTypeId;

  @override
  PdfAttachmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return PdfAttachmentModel(
      id: fields[0] as String? ?? const Uuid().v4(),
      noteId: fields[1] as String? ?? '',
      fileName: fields[2] as String? ?? '',
      filePath: fields[3] as String? ?? '',
      fileSize: fields[4] as int? ?? 0,
      pageCount: fields[5] as int? ?? 0,
      thumbnailPath: fields[6] as String?,
      isEncrypted: fields[7] as bool? ?? false,
      isCompressed: fields[8] as bool? ?? false,
      uploadedAt: fields[9] as DateTime? ?? DateTime.now(),
      lastOpenedAt: fields[10] as DateTime?,
      extractedText: fields[11] as String?,
      annotations: (fields[12] as List?)?.cast<PdfAnnotation>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, PdfAttachmentModel obj) {
    writer
      ..writeByte(13) // Number of fields
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.noteId)
      ..writeByte(2)..write(obj.fileName)
      ..writeByte(3)..write(obj.filePath)
      ..writeByte(4)..write(obj.fileSize)
      ..writeByte(5)..write(obj.pageCount)
      ..writeByte(6)..write(obj.thumbnailPath)
      ..writeByte(7)..write(obj.isEncrypted)
      ..writeByte(8)..write(obj.isCompressed)
      ..writeByte(9)..write(obj.uploadedAt)
      ..writeByte(10)..write(obj.lastOpenedAt)
      ..writeByte(11)..write(obj.extractedText)
      ..writeByte(12)..write(obj.annotations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAttachmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

@HiveType(typeId: pdfAttachmentModelTypeId)
class PdfAttachmentModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String noteId;
  
  @HiveField(2)
  String fileName;
  
  @HiveField(3)
  final String filePath;
  
  @HiveField(4)
  final int fileSize; // in bytes
  
  @HiveField(5)
  final int pageCount;
  
  @HiveField(6)
  String? thumbnailPath;
  
  @HiveField(7)
  final bool isEncrypted;
  
  @HiveField(8)
  final bool isCompressed;
  
  @HiveField(9)
  final DateTime uploadedAt;
  
  @HiveField(10)
  DateTime? lastOpenedAt;
  
  @HiveField(11)
  String? extractedText;
  
  @HiveField(12)
  List<PdfAnnotation> annotations;

  PdfAttachmentModel({
    String? id,
    required this.noteId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.pageCount,
    this.thumbnailPath,
    this.isEncrypted = false,
    this.isCompressed = false,
    DateTime? uploadedAt,
    this.lastOpenedAt,
    this.extractedText,
    List<PdfAnnotation>? annotations,
  })  : id = id ?? const Uuid().v4(),
        uploadedAt = uploadedAt ?? DateTime.now(),
        annotations = annotations ?? [];

  // Get file size in human-readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  PdfAttachmentModel copyWith({
    String? id,
    String? noteId,
    String? fileName,
    String? filePath,
    int? fileSize,
    int? pageCount,
    String? thumbnailPath,
    bool? isEncrypted,
    bool? isCompressed,
    DateTime? uploadedAt,
    DateTime? lastOpenedAt,
    String? extractedText,
    List<PdfAnnotation>? annotations,
  }) {
    return PdfAttachmentModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isCompressed: isCompressed ?? this.isCompressed,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      extractedText: extractedText ?? this.extractedText,
      annotations: annotations ?? List.from(this.annotations),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'thumbnailPath': thumbnailPath,
      'isEncrypted': isEncrypted,
      'isCompressed': isCompressed,
      'uploadedAt': uploadedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'extractedText': extractedText,
      'annotations': annotations.map((a) => a.toMap()).toList(),
    };
  }

  factory PdfAttachmentModel.fromMap(Map<String, dynamic> map) {
    return PdfAttachmentModel(
      id: map['id'] ?? const Uuid().v4(),
      noteId: map['noteId'] ?? '',
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      pageCount: map['pageCount'] ?? 0,
      thumbnailPath: map['thumbnailPath'],
      isEncrypted: map['isEncrypted'] ?? false,
      isCompressed: map['isCompressed'] ?? false,
      uploadedAt: map['uploadedAt'] != null 
          ? DateTime.parse(map['uploadedAt']) 
          : DateTime.now(),
      lastOpenedAt: map['lastOpenedAt'] != null 
          ? DateTime.parse(map['lastOpenedAt']) 
          : null,
      extractedText: map['extractedText'],
      annotations: (map['annotations'] as List?)
          ?.map((a) => PdfAnnotation.fromMap(a))
          .toList() ?? [],
    );
  }
}

// Hive Type ID for PdfAnnotation
const int pdfAnnotationTypeId = 2;

// Manual Hive Adapter for PdfAnnotation
class PdfAnnotationAdapter extends TypeAdapter<PdfAnnotation> {
  @override
  final int typeId = pdfAnnotationTypeId;

  @override
  PdfAnnotation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return PdfAnnotation(
      id: fields[0] as String? ?? const Uuid().v4(),
      pageNumber: fields[1] as int? ?? 0,
      type: fields[2] as String? ?? 'highlight',
      text: fields[3] as String?,
      color: fields[4] as String? ?? '#FFFF00',
      bounds: fields[5] as String?,
      createdAt: fields[6] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, PdfAnnotation obj) {
    writer
      ..writeByte(7) // Number of fields
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.pageNumber)
      ..writeByte(2)..write(obj.type)
      ..writeByte(3)..write(obj.text)
      ..writeByte(4)..write(obj.color)
      ..writeByte(5)..write(obj.bounds)
      ..writeByte(6)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAnnotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

@HiveType(typeId: pdfAnnotationTypeId)
class PdfAnnotation {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final int pageNumber;
  
  @HiveField(2)
  final String type; // highlight, underline, comment
  
  @HiveField(3)
  final String? text;
  
  @HiveField(4)
  final String color; // hex color
  
  @HiveField(5)
  final String? bounds; // JSON string of bounds
  
  @HiveField(6)
  final DateTime createdAt;

  PdfAnnotation({
    String? id,
    required this.pageNumber,
    required this.type,
    this.text,
    this.color = '#FFFF00',
    this.bounds,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'type': type,
      'text': text,
      'color': color,
      'bounds': bounds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PdfAnnotation.fromMap(Map<String, dynamic> map) {
    return PdfAnnotation(
      id: map['id'] ?? const Uuid().v4(),
      pageNumber: map['pageNumber'] ?? 0,
      type: map['type'] ?? 'highlight',
      text: map['text'],
      color: map['color'] ?? '#FFFF00',
      bounds: map['bounds'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}

// Register the adapters
void registerPdfHiveAdapters() {
  if (!Hive.isAdapterRegistered(pdfAttachmentModelTypeId)) {
    Hive.registerAdapter(PdfAttachmentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(pdfAnnotationTypeId)) {
    Hive.registerAdapter(PdfAnnotationAdapter());
  }
}
