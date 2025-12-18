import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// Hive Type IDs for PDF Edit Models
const int pdfEditHistoryTypeId = 10;
const int pdfTextElementTypeId = 11;
const int pdfVersionTypeId = 12;
const int pdfSignatureTypeId = 13;
const int pdfImageElementTypeId = 14;

/// Represents a single edit action in PDF history
@HiveType(typeId: pdfEditHistoryTypeId)
class PdfEditHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String pdfId;

  @HiveField(2)
  final String action; // 'text_edit', 'text_add', 'text_delete', 'format', 'image_add', 'signature_add'

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final Map<String, dynamic> data; // Stores action-specific data

  @HiveField(5)
  final String? description;

  PdfEditHistory({
    String? id,
    required this.pdfId,
    required this.action,
    DateTime? timestamp,
    required this.data,
    this.description,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdfId': pdfId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'description': description,
    };
  }

  factory PdfEditHistory.fromMap(Map<String, dynamic> map) {
    return PdfEditHistory(
      id: map['id'],
      pdfId: map['pdfId'],
      action: map['action'],
      timestamp: DateTime.parse(map['timestamp']),
      data: Map<String, dynamic>.from(map['data']),
      description: map['description'],
    );
  }
}

/// Represents a text element in PDF with formatting
@HiveType(typeId: pdfTextElementTypeId)
class PdfTextElement {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int pageNumber;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final double x;

  @HiveField(4)
  final double y;

  @HiveField(5)
  final double width;

  @HiveField(6)
  final double height;

  @HiveField(7)
  final String fontFamily;

  @HiveField(8)
  final double fontSize;

  @HiveField(9)
  final String color; // Hex color

  @HiveField(10)
  final bool isBold;

  @HiveField(11)
  final bool isItalic;

  @HiveField(12)
  final bool isUnderline;

  @HiveField(13)
  final String alignment; // 'left', 'center', 'right', 'justify'

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime? modifiedAt;

  PdfTextElement({
    String? id,
    required this.pageNumber,
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.fontFamily = 'Helvetica',
    this.fontSize = 12.0,
    this.color = '#000000',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.alignment = 'left',
    DateTime? createdAt,
    this.modifiedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  PdfTextElement copyWith({
    String? text,
    double? x,
    double? y,
    double? width,
    double? height,
    String? fontFamily,
    double? fontSize,
    String? color,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    String? alignment,
    DateTime? modifiedAt,
  }) {
    return PdfTextElement(
      id: id,
      pageNumber: pageNumber,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      alignment: alignment ?? this.alignment,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'text': text,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'color': color,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'alignment': alignment,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory PdfTextElement.fromMap(Map<String, dynamic> map) {
    return PdfTextElement(
      id: map['id'],
      pageNumber: map['pageNumber'],
      text: map['text'],
      x: map['x'],
      y: map['y'],
      width: map['width'],
      height: map['height'],
      fontFamily: map['fontFamily'] ?? 'Helvetica',
      fontSize: map['fontSize'] ?? 12.0,
      color: map['color'] ?? '#000000',
      isBold: map['isBold'] ?? false,
      isItalic: map['isItalic'] ?? false,
      isUnderline: map['isUnderline'] ?? false,
      alignment: map['alignment'] ?? 'left',
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: map['modifiedAt'] != null ? DateTime.parse(map['modifiedAt']) : null,
    );
  }
}

/// Represents a PDF version for comparison and rollback
@HiveType(typeId: pdfVersionTypeId)
class PdfVersion {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String pdfId;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final int versionNumber;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final int fileSize;

  @HiveField(7)
  final bool isAutoBackup;

  PdfVersion({
    String? id,
    required this.pdfId,
    required this.filePath,
    required this.versionNumber,
    DateTime? createdAt,
    this.description,
    required this.fileSize,
    this.isAutoBackup = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdfId': pdfId,
      'filePath': filePath,
      'versionNumber': versionNumber,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'fileSize': fileSize,
      'isAutoBackup': isAutoBackup,
    };
  }

  factory PdfVersion.fromMap(Map<String, dynamic> map) {
    return PdfVersion(
      id: map['id'],
      pdfId: map['pdfId'],
      filePath: map['filePath'],
      versionNumber: map['versionNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      description: map['description'],
      fileSize: map['fileSize'],
      isAutoBackup: map['isAutoBackup'] ?? false,
    );
  }
}

/// Represents a signature element in PDF
@HiveType(typeId: pdfSignatureTypeId)
class PdfSignature {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int pageNumber;

  @HiveField(2)
  final String imagePath; // Path to signature image

  @HiveField(3)
  final double x;

  @HiveField(4)
  final double y;

  @HiveField(5)
  final double width;

  @HiveField(6)
  final double height;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final String? signerName;

  PdfSignature({
    String? id,
    required this.pageNumber,
    required this.imagePath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    DateTime? createdAt,
    this.signerName,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'imagePath': imagePath,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'createdAt': createdAt.toIso8601String(),
      'signerName': signerName,
    };
  }

  factory PdfSignature.fromMap(Map<String, dynamic> map) {
    return PdfSignature(
      id: map['id'],
      pageNumber: map['pageNumber'],
      imagePath: map['imagePath'],
      x: map['x'],
      y: map['y'],
      width: map['width'],
      height: map['height'],
      createdAt: DateTime.parse(map['createdAt']),
      signerName: map['signerName'],
    );
  }
}

/// Represents an image element in PDF
@HiveType(typeId: pdfImageElementTypeId)
class PdfImageElement {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int pageNumber;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  final double x;

  @HiveField(4)
  final double y;

  @HiveField(5)
  final double width;

  @HiveField(6)
  final double height;

  @HiveField(7)
  final DateTime createdAt;

  PdfImageElement({
    String? id,
    required this.pageNumber,
    required this.imagePath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pageNumber': pageNumber,
      'imagePath': imagePath,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PdfImageElement.fromMap(Map<String, dynamic> map) {
    return PdfImageElement(
      id: map['id'],
      pageNumber: map['pageNumber'],
      imagePath: map['imagePath'],
      x: map['x'],
      y: map['y'],
      width: map['width'],
      height: map['height'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

/// Register Hive adapters for PDF edit models
void registerPdfEditHiveAdapters() {
  // Note: Manual adapters need to be created for Hive serialization
  // For now, we'll use JSON serialization via toMap/fromMap
}
