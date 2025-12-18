import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/pdf_attachment_model.dart';
import 'pdf_storage_service.dart';

class PdfBackupService {
  // Backup all PDFs for a note
  static Future<File?> backupNotePdfs(String noteId) async {
    try {
      final attachments = PdfStorageService.getPdfAttachmentsForNote(noteId);
      if (attachments.isEmpty) return null;

      // Create backup data
      final backupData = {
        'noteId': noteId,
        'timestamp': DateTime.now().toIso8601String(),
        'attachments': attachments.map((a) => a.toMap()).toList(),
      };

      // Save to backup file
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/pdf_backup_${noteId}_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonEncode(backupData));

      return backupFile;
    } catch (e) {
      // Failed to backup PDFs
      return null;
    }
  }

  // Restore PDFs from backup
  static Future<bool> restoreNotePdfs(File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      final noteId = backupData['noteId'] as String;
      final attachmentsData = backupData['attachments'] as List;

      final attachments = attachmentsData
          .map((data) => PdfAttachmentModel.fromMap(data as Map<String, dynamic>))
          .toList();

      // Restore each attachment
      for (var attachment in attachments) {
        final file = File(attachment.filePath);
        if (await file.exists()) {
          await PdfStorageService.updatePdfAttachment(attachment);
        }
      }

      return true;
    } catch (e) {
      // Failed to restore PDFs
      return false;
    }
  }

  // Export note PDFs to external location
  static Future<Directory?> exportNotePdfs(String noteId, String destinationPath) async {
    try {
      final attachments = PdfStorageService.getPdfAttachmentsForNote(noteId);
      if (attachments.isEmpty) return null;

      final exportDir = Directory('$destinationPath/note_${noteId}_pdfs');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Copy each PDF
      for (var attachment in attachments) {
        final file = File(attachment.filePath);
        if (await file.exists()) {
          final destFile = File('${exportDir.path}/${attachment.fileName}');
          await file.copy(destFile.path);
        }
      }

      // Create metadata file
      final metadata = {
        'noteId': noteId,
        'exportDate': DateTime.now().toIso8601String(),
        'attachments': attachments.map((a) => {
          'fileName': a.fileName,
          'pageCount': a.pageCount,
          'fileSize': a.fileSize,
        }).toList(),
      };

      final metadataFile = File('${exportDir.path}/metadata.json');
      await metadataFile.writeAsString(jsonEncode(metadata));

      return exportDir;
    } catch (e) {
      // Failed to export PDFs
      return null;
    }
  }

  // Import PDFs from external location
  static Future<List<PdfAttachmentModel>> importNotePdfs(
    String noteId,
    Directory sourceDir,
  ) async {
    try {
      final List<PdfAttachmentModel> imported = [];
      final files = sourceDir.listSync().whereType<File>().where((f) => f.path.endsWith('.pdf'));

      for (var file in files) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final attachment = await PdfStorageService.savePdfAttachment(
          noteId: noteId,
          pdfFile: file,
          fileName: fileName,
        );

        if (attachment != null) {
          imported.add(attachment);
        }
      }

      return imported;
    } catch (e) {
      // Failed to import PDFs
      return [];
    }
  }

  // Get backup directory
  static Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/pdf_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // List all backup files
  static Future<List<File>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      final files = backupDir.listSync().whereType<File>().toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      // Failed to list backups
      return [];
    }
  }

  // Delete old backups (keep only last N backups)
  static Future<void> cleanupOldBackups({int keepCount = 10}) async {
    try {
      final backups = await listBackups();
      if (backups.length > keepCount) {
        final toDelete = backups.sublist(keepCount);
        for (var file in toDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      // Failed to cleanup backups
    }
  }

  // Sync PDFs between devices (via Bluetooth or file transfer)
  static Future<Map<String, dynamic>> prepareSyncData(String noteId) async {
    try {
      final attachments = PdfStorageService.getPdfAttachmentsForNote(noteId);
      
      final syncData = {
        'noteId': noteId,
        'timestamp': DateTime.now().toIso8601String(),
        'attachments': attachments.map((a) => {
          'id': a.id,
          'fileName': a.fileName,
          'filePath': a.filePath,
          'fileSize': a.fileSize,
          'pageCount': a.pageCount,
          'isEncrypted': a.isEncrypted,
          'isCompressed': a.isCompressed,
        }).toList(),
      };

      return syncData;
    } catch (e) {
      // Failed to prepare sync data
      return {};
    }
  }

  // Receive sync data from another device
  static Future<bool> receiveSyncData(
    Map<String, dynamic> syncData,
    List<File> pdfFiles,
  ) async {
    try {
      final noteId = syncData['noteId'] as String;
      final attachmentsData = syncData['attachments'] as List;

      for (int i = 0; i < attachmentsData.length && i < pdfFiles.length; i++) {
        final data = attachmentsData[i] as Map<String, dynamic>;
        final file = pdfFiles[i];

        await PdfStorageService.savePdfAttachment(
          noteId: noteId,
          pdfFile: file,
          fileName: data['fileName'] as String,
          compress: data['isCompressed'] as bool? ?? false,
          encrypt: data['isEncrypted'] as bool? ?? false,
        );
      }

      return true;
    } catch (e) {
      // Failed to receive sync data
      return false;
    }
  }
}
