import 'dart:async';
import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter/foundation.dart';
import '../models/pdf_attachment_model.dart';
import 'pdf_storage_service.dart';

/// Data class for shared PDF files
class SharedPdfData {
  final File file;
  final String fileName;
  final bool isEncrypted;
  
  SharedPdfData({
    required this.file,
    required this.fileName,
    required this.isEncrypted,
  });
}

/// Service to handle PDF files shared/opened from external apps
class PdfSharingService {
  static StreamSubscription? _intentDataStreamSubscription;
  static final _sharedPdfController = StreamController<PdfAttachmentModel>.broadcast();
  static final _pendingPdfController = StreamController<SharedPdfData>.broadcast();
  static final _receiveSharingIntent = ReceiveSharingIntent.instance;
  
  /// Stream of PDFs received from external apps (already imported)
  static Stream<PdfAttachmentModel> get sharedPdfStream => _sharedPdfController.stream;
  
  /// Stream of PDFs that need password input
  static Stream<SharedPdfData> get pendingPdfStream => _pendingPdfController.stream;
  
  /// Initialize the sharing service
  static Future<void> initialize() async {
    debugPrint('[PDF Sharing] Initializing PDF sharing service');
    
    // Listen for shared files while app is running (for media files)
    _intentDataStreamSubscription = _receiveSharingIntent.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        debugPrint('[PDF Sharing] Received media stream: ${value.length} files');
        _handleSharedFiles(value);
      },
      onError: (err) {
        debugPrint('[PDF Sharing] Error receiving shared files: $err');
      },
    );

    // Get the initial shared files when app is opened from external source
    _receiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      debugPrint('[PDF Sharing] Initial media: ${value.length} files');
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
      // Clear the initial shared files to avoid processing them again
      _receiveSharingIntent.reset();
    });
    
  }
  
  /// Handle shared files
  static Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    for (var file in files) {
      if (file.path.toLowerCase().endsWith('.pdf')) {
        try {
          final pdfFile = File(file.path);
          if (await pdfFile.exists()) {
            // Check if PDF is encrypted
            final isEncrypted = await PdfStorageService.isPdfEncrypted(pdfFile);
            final fileName = file.path.split('/').last;
            
            if (isEncrypted) {
              // Send to pending stream for password input
              debugPrint('PDF is encrypted, sending to pending stream: $fileName');
              _pendingPdfController.add(SharedPdfData(
                file: pdfFile,
                fileName: fileName,
                isEncrypted: true,
              ));
            } else {
              debugPrint('PDF is not encrypted, importing directly: $fileName');
              // Import non-encrypted PDF directly
              final attachment = await importSharedPdf(pdfFile, null);
              if (attachment != null) {
                _sharedPdfController.add(attachment);
              } else {
                debugPrint('Failed to import PDF or duplicate detected: $fileName');
              }
            }
          }
        } catch (e) {
          debugPrint('Error handling shared PDF: $e');
        }
      }
    }
  }
  
  /// Import a shared PDF file to the app's library
  static Future<PdfAttachmentModel?> importSharedPdf(File pdfFile, String? password) async {
    try {
      // Get file name
      final fileName = pdfFile.path.split('/').last;
      
      // Save to library (using a special library note ID)
      // Skip compression for faster loading - will be done in background
      final attachment = await PdfStorageService.savePdfAttachment(
        noteId: 'pdf_library', // Special ID for library PDFs
        pdfFile: pdfFile,
        fileName: fileName,
        compress: true, // Will be done in background
        encrypt: false,
        password: password,
        skipCompression: false, // Allow background compression
      );
      
      return attachment;
    } catch (e) {
      debugPrint('Error importing shared PDF: $e');
      return null;
    }
  }
  
  /// Dispose the service
  static void dispose() {
    _intentDataStreamSubscription?.cancel();
    _sharedPdfController.close();
    _pendingPdfController.close();
  }
}
