import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pdf_attachment_model.dart';
import '../services/pdf_storage_service.dart';
import '../services/pdf_text_extraction_service.dart';

class PdfProvider extends ChangeNotifier {
  static const String libraryNoteId = 'pdf_library';

  List<PdfAttachmentModel> _attachments = [];
  List<PdfAttachmentModel> _libraryPdfs = [];
  List<PdfAttachmentModel> _recentPdfs = [];
  bool _isLoading = false;
  String? _error;

  List<PdfAttachmentModel> get attachments => _attachments;
  List<PdfAttachmentModel> get libraryPdfs => _libraryPdfs;
  List<PdfAttachmentModel> get recentPdfs => _recentPdfs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await loadLibraryPdfs();
    await loadRecentPdfs();
  }

  // Load PDFs for a specific note
  Future<void> loadPdfsForNote(String noteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attachments = PdfStorageService.getPdfAttachmentsForNote(noteId);
    } catch (e) {
      _error = 'Failed to load PDFs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load PDFs stored in the library collection
  Future<void> loadLibraryPdfs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _libraryPdfs = PdfStorageService.getPdfAttachmentsForNote(libraryNoteId);
    } catch (e) {
      _error = 'Failed to load PDFs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load recently opened PDFs
  Future<void> loadRecentPdfs() async {
    try {
      _recentPdfs = PdfStorageService.getRecentlyOpenedPdfs();
      notifyListeners();
    } catch (e) {
      // Failed to load recent PDFs
    }
  }

  // Pick and attach PDF file
  Future<PdfAttachmentModel?> pickAndAttachPdf({
    required String noteId,
    bool compress = true,
    bool encrypt = false,
    String? password,
    File? pickedFile,
    String? pickedFileName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      File file;
      String fileName;
      
      if (pickedFile != null && pickedFileName != null) {
        // Use provided file (for retry with password)
        file = pickedFile;
        fileName = pickedFileName;
      } else {
        // Pick PDF file
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) {
          _isLoading = false;
          notifyListeners();
          return null;
        }

        file = File(result.files.single.path!);
        fileName = result.files.single.name;
      }

      // Save PDF attachment
      final attachment = await PdfStorageService.savePdfAttachment(
        noteId: noteId,
        pdfFile: file,
        fileName: fileName,
        compress: compress,
        encrypt: encrypt,
        password: password,
      );

      if (attachment != null) {
        _attachments.add(attachment);
        if (attachment.noteId == libraryNoteId) {
          _libraryPdfs = [attachment, ..._libraryPdfs]
            ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        }
        
        // Extract text in background
        _extractTextInBackground(attachment.id);
      }

      return attachment;
    } catch (e) {
      _error = 'Failed to attach PDF: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check if a file is an encrypted PDF
  Future<bool> isFileEncrypted(File file) async {
    return await PdfStorageService.isPdfEncrypted(file);
  }

  // Extract text in background
  Future<void> _extractTextInBackground(String pdfId) async {
    try {
      await PdfTextExtractionService.extractAndSaveText(pdfId);
      // Reload attachments to get updated text
      final attachment = PdfStorageService.getPdfAttachment(pdfId);
      if (attachment != null) {
        final index = _attachments.indexWhere((a) => a.id == pdfId);
        if (index != -1) {
          _attachments[index] = attachment;
          notifyListeners();
        }

        final libraryIndex = _libraryPdfs.indexWhere((a) => a.id == pdfId);
        if (libraryIndex != -1) {
          _libraryPdfs[libraryIndex] = attachment;
          notifyListeners();
        }
      }
    } catch (e) {
      // Background text extraction failed
    }
  }

  // Rename PDF
  Future<void> renamePdf(String pdfId, String newFileName) async {
    try {
      await PdfStorageService.renamePdfAttachment(pdfId, newFileName);
      
      final index = _attachments.indexWhere((a) => a.id == pdfId);
      if (index != -1) {
        final updated = _attachments[index].copyWith(fileName: newFileName);
        _attachments[index] = updated;
        notifyListeners();
      }

      final libraryIndex = _libraryPdfs.indexWhere((a) => a.id == pdfId);
      if (libraryIndex != -1) {
        final updated = _libraryPdfs[libraryIndex].copyWith(fileName: newFileName);
        _libraryPdfs[libraryIndex] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to rename PDF: $e';
      notifyListeners();
    }
  }

  // Delete PDF
  Future<void> deletePdf(String pdfId) async {
    try {
      await PdfStorageService.deletePdfAttachment(pdfId);
      _attachments.removeWhere((a) => a.id == pdfId);
      _libraryPdfs.removeWhere((a) => a.id == pdfId);
      _recentPdfs.removeWhere((a) => a.id == pdfId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete PDF: $e';
      notifyListeners();
    }
  }

  // Update last opened
  Future<void> markPdfAsOpened(String pdfId) async {
    try {
      await PdfStorageService.updateLastOpened(pdfId);
      await loadRecentPdfs();
    } catch (e) {
      // Failed to update last opened
    }
  }

  // Search in PDF
  Future<List<SearchResult>> searchInPdf(
    String pdfId,
    String query, {
    bool caseSensitive = false,
  }) async {
    try {
      return await PdfTextExtractionService.searchInPdf(
        pdfId,
        query,
        caseSensitive: caseSensitive,
      );
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  // Search in all PDFs of a note
  Future<Map<String, List<SearchResult>>> searchInNotePdfs(
    String noteId,
    String query, {
    bool caseSensitive = false,
  }) async {
    try {
      final pdfIds = _attachments.map((a) => a.id).toList();
      return await PdfTextExtractionService.searchInMultiplePdfs(
        pdfIds,
        query,
        caseSensitive: caseSensitive,
      );
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return {};
    }
  }

  // Get PDF summary
  Future<String> getPdfSummary(String pdfId, {int maxLength = 500}) async {
    try {
      return await PdfTextExtractionService.extractAndSummarize(
        pdfId,
        maxLength: maxLength,
      );
    } catch (e) {
      return '';
    }
  }

  // Add annotation to PDF
  Future<void> addAnnotation(String pdfId, PdfAnnotation annotation) async {
    try {
      final attachment = PdfStorageService.getPdfAttachment(pdfId);
      if (attachment != null) {
        final annotations = List<PdfAnnotation>.from(attachment.annotations);
        annotations.add(annotation);
        final updated = attachment.copyWith(annotations: annotations);
        await PdfStorageService.updatePdfAttachment(updated);
        
        final index = _attachments.indexWhere((a) => a.id == pdfId);
        if (index != -1) {
          _attachments[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Failed to add annotation: $e';
      notifyListeners();
    }
  }

  // Remove annotation from PDF
  Future<void> removeAnnotation(String pdfId, String annotationId) async {
    try {
      final attachment = PdfStorageService.getPdfAttachment(pdfId);
      if (attachment != null) {
        final annotations = attachment.annotations
            .where((a) => a.id != annotationId)
            .toList();
        final updated = attachment.copyWith(annotations: annotations);
        await PdfStorageService.updatePdfAttachment(updated);
        
        final index = _attachments.indexWhere((a) => a.id == pdfId);
        if (index != -1) {
          _attachments[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Failed to remove annotation: $e';
      notifyListeners();
    }
  }

  // Get total storage used
  Future<String> getTotalStorageUsed() async {
    try {
      final bytes = await PdfStorageService.getTotalStorageUsed();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return '0 B';
    }
  }

  // Export PDF
  Future<File?> exportPdf(String pdfId, String destinationPath) async {
    try {
      return await PdfStorageService.exportPdf(pdfId, destinationPath);
    } catch (e) {
      _error = 'Failed to export PDF: $e';
      notifyListeners();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get PDF count for note
  int getPdfCountForNote(String noteId) {
    return _attachments.where((a) => a.noteId == noteId).length;
  }

  // Check if note has PDFs
  bool noteHasPdfs(String noteId) {
    return _attachments.any((a) => a.noteId == noteId);
  }
}
