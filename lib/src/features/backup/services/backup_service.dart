import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

/// Service for offline backup and restore
class BackupService {
  /// Create backup of all data
  static Future<File> createBackup(List<Map<String, dynamic>> notes) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'calcnote_backup_$timestamp.json';
    
    final backup = {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'notes_count': notes.length,
      'notes': notes,
    };
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
    
    // Get documents directory
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    
    // Create backups directory if it doesn't exist
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    // Write backup file
    final file = File('${backupDir.path}/$fileName');
    await file.writeAsString(jsonString);
    
    return file;
  }
  
  /// Export backup file
  static Future<void> exportBackup(File backupFile) async {
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      subject: 'CalcNote Backup',
      text: 'CalcNote backup file - ${backupFile.path.split('/').last}',
    );
  }
  
  /// Restore from backup file
  static Future<List<Map<String, dynamic>>> restoreFromBackup(File backupFile) async {
    final jsonString = await backupFile.readAsString();
    final backup = jsonDecode(jsonString) as Map<String, dynamic>;
    
    if (backup['notes'] is List) {
      return List<Map<String, dynamic>>.from(backup['notes']);
    }
    
    return [];
  }
  
  /// Get list of all backups
  static Future<List<BackupInfo>> getBackupList() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    
    if (!await backupDir.exists()) {
      return [];
    }
    
    final files = await backupDir.list().toList();
    final backups = <BackupInfo>[];
    
    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        final stat = await file.stat();
        final jsonString = await file.readAsString();
        final backup = jsonDecode(jsonString) as Map<String, dynamic>;
        
        backups.add(BackupInfo(
          file: file,
          fileName: file.path.split('/').last,
          size: stat.size,
          createdAt: DateTime.parse(backup['timestamp'] as String),
          notesCount: backup['notes_count'] as int,
        ));
      }
    }
    
    // Sort by date (newest first)
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return backups;
  }
  
  /// Delete backup file
  static Future<void> deleteBackup(File backupFile) async {
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
  }
  
  /// Auto backup (create backup automatically)
  static Future<File?> autoBackup(List<Map<String, dynamic>> notes) async {
    try {
      // Only create auto backup if there are notes
      if (notes.isEmpty) return null;
      
      // Check if auto backup was created today
      final backups = await getBackupList();
      final today = DateTime.now();
      
      final todayBackup = backups.where((b) =>
        b.createdAt.year == today.year &&
        b.createdAt.month == today.month &&
        b.createdAt.day == today.day
      ).toList();
      
      // If backup already exists today, skip
      if (todayBackup.isNotEmpty) return null;
      
      // Create backup
      return await createBackup(notes);
    } catch (e) {
      print('Auto backup error: $e');
      return null;
    }
  }
  
  /// Get backup size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Backup information model
class BackupInfo {
  final File file;
  final String fileName;
  final int size;
  final DateTime createdAt;
  final int notesCount;
  
  BackupInfo({
    required this.file,
    required this.fileName,
    required this.size,
    required this.createdAt,
    required this.notesCount,
  });
  
  String get formattedSize => BackupService.formatFileSize(size);
  
  String get formattedDate => DateFormat('MMM dd, yyyy HH:mm').format(createdAt);
}
