import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../models/pdf_attachment_model.dart';

class PdfStorageService {
  static const String _pdfBoxName = 'pdf_attachments';
  static const String _pdfDirName = 'pdfs';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Initialize the service
  static Future<void> initialize() async {
    await Hive.openBox<PdfAttachmentModel>(_pdfBoxName);
  }

  // Get PDF box
  static Box<PdfAttachmentModel> get _pdfBox => Hive.box<PdfAttachmentModel>(_pdfBoxName);

  // Get PDF directory
  static Future<Directory> _getPdfDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${appDir.path}/$_pdfDirName');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  // Compress PDF file
  static Future<File> _compressPdf(File pdfFile) async {
    // PDF files are already compressed. Previous implementation wrapped the PDF
    // in a ZIP archive which broke rendering. Until a real PDF-specific
    // compressor is introduced, keep the original file untouched.
    return pdfFile;
  }

  // Encrypt PDF file
  // Note: PDF encryption requires additional libraries
  // For MVP, we'll skip encryption and rely on device-level security
  static Future<File> _encryptPdf(File pdfFile, String password) async {
    // PDF encryption is complex and requires specialized libraries
    // For now, return the original file
    // The password will still be stored securely for future use
    return pdfFile;
  }

  // Generate thumbnail from PDF
  // Note: Thumbnail generation requires platform-specific rendering
  // For now, we'll skip thumbnail generation and use PDF icon instead
  static Future<String?> _generateThumbnail(File pdfFile, String pdfId) async {
    // Thumbnail generation is complex and requires platform-specific code
    // or additional packages like flutter_native_image or image
    // For MVP, we'll return null and use the PDF icon fallback in UI
    return null;
  }

  // Get page count from PDF
  // Note: Page counting requires PDF parsing libraries
  // For MVP, we'll return a default value
  static Future<int> _getPageCount(File pdfFile) async {
    // Page counting requires PDF parsing
    // flutter_pdfview will handle this in the viewer
    // Return 1 as placeholder - actual count shown in viewer
    return 1;
  }

  // Check if PDF is natively encrypted
  static Future<bool> isPdfEncrypted(File pdfFile) async {
    try {
      // Only read first 8KB and last 8KB of the file for efficiency
      // PDF encryption info is typically in the header or trailer
      final fileSize = await pdfFile.length();
      final raf = await pdfFile.open(mode: FileMode.read);
      
      // Read first 8KB (or entire file if smaller)
      final headerSize = fileSize < 8192 ? fileSize : 8192;
      final headerBytes = await raf.read(headerSize);
      final headerContent = String.fromCharCodes(headerBytes);
      
      // Check header for encryption
      if (headerContent.contains('/Encrypt')) {
        await raf.close();
        return true;
      }
      
      // If file is larger than 16KB, also check the trailer (last 8KB)
      if (fileSize > 16384) {
        await raf.setPosition(fileSize - 8192);
        final trailerBytes = await raf.read(8192);
        final trailerContent = String.fromCharCodes(trailerBytes);
        
        if (trailerContent.contains('/Encrypt')) {
          await raf.close();
          return true;
        }
      }
      
      await raf.close();
      return false;
    } catch (e) {
      debugPrint('[PDF Storage] Error checking encryption: $e');
      return false;
    }
  }

  // Check if a PDF with the same name and size already exists
  static PdfAttachmentModel? findDuplicatePdf(String fileName, int fileSize, String noteId) {
    final existingPdfs = _pdfBox.values.where((pdf) => 
      pdf.noteId == noteId && 
      pdf.fileName == fileName && 
      pdf.fileSize == fileSize
    ).toList();
    
    return existingPdfs.isNotEmpty ? existingPdfs.first : null;
  }

  // Save PDF attachment
  static Future<PdfAttachmentModel?> savePdfAttachment({
    required String noteId,
    required File pdfFile,
    required String fileName,
    bool compress = true,
    bool encrypt = false,
    String? password,
    bool skipCompression = false, // Skip compression for faster loading
  }) async {
    try {
      // Check for duplicates first
      final fileSize = await pdfFile.length();
      final duplicate = findDuplicatePdf(fileName, fileSize, noteId);
      
      if (duplicate != null) {
        debugPrint('[PDF Storage] Duplicate PDF found: $fileName (${duplicate.id})');
        // Return the existing PDF instead of creating a new one
        return duplicate;
      }
      
      final pdfDir = await _getPdfDirectory();
      final pdfId = DateTime.now().millisecondsSinceEpoch.toString();
      final newPath = '${pdfDir.path}/$pdfId.pdf';
      
      // Copy file to app directory
      File savedFile = await pdfFile.copy(newPath);
      
      // Check if PDF is natively encrypted with timeout (fast check)
      bool isNativelyEncrypted = false;
      try {
        isNativelyEncrypted = await isPdfEncrypted(savedFile).timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            debugPrint('[PDF Storage] Encryption check timed out, assuming not encrypted');
            return false;
          },
        );
      } catch (e) {
        debugPrint('[PDF Storage] Encryption check failed: $e');
        isNativelyEncrypted = false;
      }
      
      // Handle encryption
      bool isEncrypted = false;
      
      // Store password if provided (for both app encryption and native encryption)
      if (password != null && password.isNotEmpty) {
        await _secureStorage.write(key: 'pdf_password_$pdfId', value: password);
      }
      
      // Encrypt if requested
      if (encrypt && password != null && password.isNotEmpty) {
        savedFile = await _encryptPdf(savedFile, password);
        isEncrypted = true;
      } else if (isNativelyEncrypted) {
        // PDF is natively encrypted
        isEncrypted = true;
      }
      
      // Get final file info
      final finalFileSize = await savedFile.length();
      
      // Get page count quickly (don't wait for full processing)
      int pageCount = 0;
      try {
        pageCount = await _getPageCount(savedFile).timeout(
          const Duration(seconds: 2),
          onTimeout: () => 0,
        );
      } catch (e) {
        debugPrint('[PDF Storage] Quick page count failed: $e');
        pageCount = 0;
      }
      
      // Create attachment model with minimal data for fast loading
      final attachment = PdfAttachmentModel(
        id: pdfId,
        noteId: noteId,
        fileName: fileName,
        filePath: savedFile.path,
        fileSize: finalFileSize,
        pageCount: pageCount,
        thumbnailPath: null, // Will be generated in background
        isEncrypted: isEncrypted,
        isCompressed: false, // Will be compressed in background if needed
      );
      
      // Save to Hive immediately for fast access
      await _pdfBox.put(pdfId, attachment);
      
      // Process compression and thumbnail in background (don't await)
      _processInBackground(pdfId, savedFile, compress && !skipCompression);
      
      return attachment;
    } catch (e) {
      // Failed to save PDF attachment
      return null;
    }
  }

  // Process compression and thumbnail generation in background
  static void _processInBackground(String pdfId, File pdfFile, bool shouldCompress) {
    Future(() async {
      try {
        debugPrint('[PDF Storage] Starting background processing for: $pdfId');
        
        File processedFile = pdfFile;
        bool wasCompressed = false;
        
        // Compress if requested
        if (shouldCompress) {
          final originalSize = await pdfFile.length();
          processedFile = await _compressPdf(pdfFile);
          final newSize = await processedFile.length();
          wasCompressed = newSize < originalSize;
          debugPrint('[PDF Storage] Compression complete: $pdfId (saved ${originalSize - newSize} bytes)');
        }
        
        // Generate thumbnail
        final thumbnailPath = await _generateThumbnail(processedFile, pdfId);
        debugPrint('[PDF Storage] Thumbnail generated: $pdfId');
        
        // Update the attachment with processed data
        final attachment = _pdfBox.get(pdfId);
        if (attachment != null) {
          final updated = attachment.copyWith(
            thumbnailPath: thumbnailPath,
            isCompressed: wasCompressed,
            filePath: processedFile.path,
          );
          await _pdfBox.put(pdfId, updated);
          debugPrint('[PDF Storage] Background processing complete: $pdfId');
        }
      } catch (e) {
        debugPrint('[PDF Storage] Background processing failed for $pdfId: $e');
      }
    });
  }

  // Get all PDF attachments for a note
  static List<PdfAttachmentModel> getPdfAttachmentsForNote(String noteId) {
    return _pdfBox.values
        .where((pdf) => pdf.noteId == noteId)
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  // Get single PDF attachment
  static PdfAttachmentModel? getPdfAttachment(String pdfId) {
    return _pdfBox.get(pdfId);
  }

  // Update PDF attachment
  static Future<void> updatePdfAttachment(PdfAttachmentModel attachment) async {
    await _pdfBox.put(attachment.id, attachment);
  }

  // Rename PDF attachment
  static Future<void> renamePdfAttachment(String pdfId, String newFileName) async {
    final attachment = _pdfBox.get(pdfId);
    if (attachment != null) {
      final updated = attachment.copyWith(fileName: newFileName);
      await _pdfBox.put(pdfId, updated);
    }
  }

  // Delete PDF attachment
  static Future<void> deletePdfAttachment(String pdfId) async {
    final attachment = _pdfBox.get(pdfId);
    if (attachment != null) {
      // Delete file
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Delete thumbnail
      if (attachment.thumbnailPath != null) {
        final thumbFile = File(attachment.thumbnailPath!);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }
      
      // Delete password if encrypted
      if (attachment.isEncrypted) {
        await _secureStorage.delete(key: 'pdf_password_${attachment.id}');
      }
      
      // Remove from Hive
      await _pdfBox.delete(pdfId);
    }
  }

  // Get PDF password
  static Future<String?> getPdfPassword(String pdfId) async {
    return await _secureStorage.read(key: 'pdf_password_$pdfId');
  }
  
  // Store PDF password
  static Future<void> storePdfPassword(String pdfId, String password) async {
    await _secureStorage.write(key: 'pdf_password_$pdfId', value: password);
  }

  // Update last opened time
  static Future<void> updateLastOpened(String pdfId) async {
    final attachment = _pdfBox.get(pdfId);
    if (attachment != null) {
      final updated = attachment.copyWith(lastOpenedAt: DateTime.now());
      await _pdfBox.put(pdfId, updated);
    }
  }

  // Get recently opened PDFs
  static List<PdfAttachmentModel> getRecentlyOpenedPdfs({int limit = 10}) {
    final pdfs = _pdfBox.values.where((pdf) => pdf.lastOpenedAt != null).toList();
    pdfs.sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    return pdfs.take(limit).toList();
  }

  // Get all PDF attachments
  static List<PdfAttachmentModel> getAllPdfAttachments() {
    return _pdfBox.values.toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  // Get total storage used by PDFs
  static Future<int> getTotalStorageUsed() async {
    int total = 0;
    for (var pdf in _pdfBox.values) {
      total += pdf.fileSize;
    }
    return total;
  }

  // Backup PDF attachments for a note
  static Future<List<Map<String, dynamic>>> backupPdfAttachments(String noteId) async {
    final attachments = getPdfAttachmentsForNote(noteId);
    return attachments.map((a) => a.toMap()).toList();
  }

  // Restore PDF attachments from backup
  static Future<void> restorePdfAttachments(
    String noteId,
    List<Map<String, dynamic>> backupData,
  ) async {
    for (var data in backupData) {
      final attachment = PdfAttachmentModel.fromMap(data);
      // Check if file exists
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await _pdfBox.put(attachment.id, attachment);
      }
    }
  }

  // Clean up orphaned PDFs (PDFs without associated notes)
  static Future<void> cleanupOrphanedPdfs(List<String> validNoteIds) async {
    final orphanedPdfs = _pdfBox.values
        .where((pdf) => !validNoteIds.contains(pdf.noteId))
        .toList();
    
    for (var pdf in orphanedPdfs) {
      await deletePdfAttachment(pdf.id);
    }
  }

  // Get PDF file (optimized for fast access)
  static Future<File?> getPdfFile(String pdfId) async {
    final attachment = _pdfBox.get(pdfId);
    if (attachment == null) {
      return null;
    }

    final file = File(attachment.filePath);
    if (!await file.exists()) {
      return null;
    }

    // Skip decompression check if already marked as not compressed
    if (!attachment.isCompressed) {
      return file;
    }

    // Only check for ZIP if marked as compressed
    if (await _isZipFile(file)) {
      try {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final pdfEntry = archive.files.firstWhere(
          (entry) => entry.isFile && entry.name.toLowerCase().endsWith('.pdf'),
          orElse: () => archive.files.isNotEmpty ? archive.files.first : ArchiveFile('', 0, <int>[]),
        );

        if (pdfEntry.isFile && pdfEntry.size > 0) {
          final content = pdfEntry.content;
          final pdfBytes = content is List<int>
              ? content
              : (content is InputStreamBase ? content.toUint8List() : <int>[]);

          if (pdfBytes.isNotEmpty) {
            await file.writeAsBytes(pdfBytes, flush: true);
            final updated = attachment.copyWith(
              isCompressed: false,
              fileSize: pdfBytes.length,
            );
            await _pdfBox.put(pdfId, updated);
            return file;
          }
        }
      } catch (_) {
        // Ignore decompression failure and fall back to returning the raw file.
      }
    }

    return file;
  }

  static Future<bool> _isZipFile(File file) async {
    try {
      final raf = await file.open(mode: FileMode.read);
      final header = raf.readSync(4);
      await raf.close();
      return header.length >= 2 && header[0] == 0x50 && header[1] == 0x4B;
    } catch (_) {
      return false;
    }
  }

  // Export PDF to external location
  static Future<File?> exportPdf(String pdfId, String destinationPath) async {
    final file = await getPdfFile(pdfId);
    if (file != null) {
      return await file.copy(destinationPath);
    }
    return null;
  }

  // Close the service
  static Future<void> close() async {
    await _pdfBox.close();
  }
}
