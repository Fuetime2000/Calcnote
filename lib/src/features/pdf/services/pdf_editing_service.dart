import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/pdf_edit_models.dart' as models;
import 'pdf_storage_service.dart';

/// Comprehensive PDF editing service with text extraction, modification, and recreation
class PdfEditingService {
  static const String _editedPdfDirName = 'edited_pdfs';
  static const String _versionsDirName = 'pdf_versions';
  static const String _signaturesDirName = 'signatures';

  /// Extract text from PDF for editing
  static Future<Map<int, List<models.PdfTextElement>>> extractTextElements(String pdfId) async {
    final file = await PdfStorageService.getPdfFile(pdfId);
    if (file == null) throw Exception('PDF file not found');

    final bytes = await file.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    final Map<int, List<models.PdfTextElement>> pageTexts = {};

    try {
      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final textExtractor = sf_pdf.PdfTextExtractor(document);
        final extractedText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);

        // Extract text with layout information
        final textLines = extractedText.split('\n');
        final elements = <models.PdfTextElement>[];

        double yPosition = 50.0;
        for (var line in textLines) {
          if (line.trim().isEmpty) continue;

          elements.add(models.PdfTextElement(
            pageNumber: i + 1,
            text: line,
            x: 50.0,
            y: yPosition,
            width: page.size.width - 100,
            height: 20.0,
            fontSize: 12.0,
          ));

          yPosition += 25.0;
        }

        pageTexts[i + 1] = elements;
      }
    } finally {
      document.dispose();
    }

    return pageTexts;
  }

  /// Extract text as plain string from PDF
  static Future<String> extractPlainText(String pdfId) async {
    final file = await PdfStorageService.getPdfFile(pdfId);
    if (file == null) throw Exception('PDF file not found');

    final bytes = await file.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    try {
      final textExtractor = sf_pdf.PdfTextExtractor(document);
      return textExtractor.extractText();
    } finally {
      document.dispose();
    }
  }

  /// Create new PDF from edited text elements using pdf package
  static Future<File> createPdfFromElements({
    required String pdfId,
    required Map<int, List<models.PdfTextElement>> pageElements,
    List<models.PdfSignature>? signatures,
    List<models.PdfImageElement>? images,
    String? password,
  }) async {
    final pdf = pw.Document();

    // Add pages and content
    for (var pageNum in pageElements.keys.toList()..sort()) {
      final elements = pageElements[pageNum] ?? [];

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: elements.map((element) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(
                    element.text,
                    style: pw.TextStyle(
                      fontSize: element.fontSize,
                      fontWeight: element.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      fontStyle: element.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
                      decoration: element.isUnderline ? pw.TextDecoration.underline : null,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    // Save to file
    final appDir = await getApplicationDocumentsDirectory();
    final editedDir = Directory('${appDir.path}/$_editedPdfDirName');
    if (!await editedDir.exists()) {
      await editedDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${editedDir.path}/edited_$pdfId\_$timestamp.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Modify existing PDF by adding text, images, or signatures
  static Future<File> modifyExistingPdf({
    required String pdfId,
    List<models.PdfTextElement>? newTextElements,
    List<models.PdfSignature>? signatures,
    List<models.PdfImageElement>? images,
    String? password,
  }) async {
    final file = await PdfStorageService.getPdfFile(pdfId);
    if (file == null) throw Exception('PDF file not found');

    final bytes = await file.readAsBytes();
    final document = sf_pdf.PdfDocument(inputBytes: bytes);

    try {
      // Add new text elements
      if (newTextElements != null) {
        for (var element in newTextElements) {
          final pageIndex = element.pageNumber - 1;
          if (pageIndex >= 0 && pageIndex < document.pages.count) {
            final page = document.pages[pageIndex];
            final graphics = page.graphics;

            // Determine font style
            sf_pdf.PdfFontStyle fontStyle;
            if (element.isBold && element.isItalic) {
              fontStyle = sf_pdf.PdfFontStyle.bold; // Syncfusion doesn't have boldItalic, use bold
            } else if (element.isBold) {
              fontStyle = sf_pdf.PdfFontStyle.bold;
            } else if (element.isItalic) {
              fontStyle = sf_pdf.PdfFontStyle.italic;
            } else {
              fontStyle = sf_pdf.PdfFontStyle.regular;
            }

            final font = sf_pdf.PdfStandardFont(
              sf_pdf.PdfFontFamily.helvetica,
              element.fontSize,
              style: fontStyle,
            );

            final brush = sf_pdf.PdfSolidBrush(_hexToColor(element.color));

            graphics.drawString(
              element.text,
              font,
              brush: brush,
              bounds: Rect.fromLTWH(element.x, element.y, element.width, element.height),
            );
          }
        }
      }

      // Add signatures
      if (signatures != null) {
        for (var signature in signatures) {
          final pageIndex = signature.pageNumber - 1;
          if (pageIndex >= 0 && pageIndex < document.pages.count) {
            final page = document.pages[pageIndex];
            final graphics = page.graphics;

            final imageFile = File(signature.imagePath);
            if (await imageFile.exists()) {
              final imageBytes = await imageFile.readAsBytes();
              final image = sf_pdf.PdfBitmap(imageBytes);
              graphics.drawImage(
                image,
                Rect.fromLTWH(signature.x, signature.y, signature.width, signature.height),
              );
            }
          }
        }
      }

      // Add images
      if (images != null) {
        for (var imageElement in images) {
          final pageIndex = imageElement.pageNumber - 1;
          if (pageIndex >= 0 && pageIndex < document.pages.count) {
            final page = document.pages[pageIndex];
            final graphics = page.graphics;

            final imageFile = File(imageElement.imagePath);
            if (await imageFile.exists()) {
              final imageBytes = await imageFile.readAsBytes();
              final image = sf_pdf.PdfBitmap(imageBytes);
              graphics.drawImage(
                image,
                Rect.fromLTWH(imageElement.x, imageElement.y, imageElement.width, imageElement.height),
              );
            }
          }
        }
      }

      // Save modified PDF
      final appDir = await getApplicationDocumentsDirectory();
      final editedDir = Directory('${appDir.path}/$_editedPdfDirName');
      if (!await editedDir.exists()) {
        await editedDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${editedDir.path}/modified_$pdfId\_$timestamp.pdf';
      final outputBytes = await document.save();
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      return outputFile;
    } finally {
      document.dispose();
    }
  }

  /// Create version backup of PDF
  static Future<models.PdfVersion> createVersionBackup(String pdfId, {String? description, bool isAutoBackup = false}) async {
    final attachment = PdfStorageService.getPdfAttachment(pdfId);
    if (attachment == null) throw Exception('PDF not found');

    final file = await PdfStorageService.getPdfFile(pdfId);
    if (file == null) throw Exception('PDF file not found');

    final appDir = await getApplicationDocumentsDirectory();
    final versionsDir = Directory('${appDir.path}/$_versionsDirName/$pdfId');
    if (!await versionsDir.exists()) {
      await versionsDir.create(recursive: true);
    }

    // Count existing versions
    final existingVersions = versionsDir.listSync().where((f) => f is File).length;
    final versionNumber = existingVersions + 1;

    final versionPath = '${versionsDir.path}/version_$versionNumber.pdf';
    await file.copy(versionPath);

    final fileSize = await File(versionPath).length();

    return models.PdfVersion(
      pdfId: pdfId,
      filePath: versionPath,
      versionNumber: versionNumber,
      description: description,
      fileSize: fileSize,
      isAutoBackup: isAutoBackup,
    );
  }

  /// Get all versions of a PDF
  static Future<List<models.PdfVersion>> getVersions(String pdfId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final versionsDir = Directory('${appDir.path}/$_versionsDirName/$pdfId');

    if (!await versionsDir.exists()) {
      return [];
    }

    final versions = <models.PdfVersion>[];
    final files = versionsDir.listSync().whereType<File>().toList();

    for (var file in files) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final versionMatch = RegExp(r'version_(\d+)\.pdf').firstMatch(fileName);

      if (versionMatch != null) {
        final versionNumber = int.parse(versionMatch.group(1)!);
        final fileSize = await file.length();
        final stat = await file.stat();

        versions.add(models.PdfVersion(
          pdfId: pdfId,
          filePath: file.path,
          versionNumber: versionNumber,
          fileSize: fileSize,
          createdAt: stat.modified,
        ));
      }
    }

    versions.sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
    return versions;
  }

  /// Restore PDF from version
  static Future<void> restoreFromVersion(String pdfId, int versionNumber) async {
    final versions = await getVersions(pdfId);
    final version = versions.firstWhere(
      (v) => v.versionNumber == versionNumber,
      orElse: () => throw Exception('Version not found'),
    );

    final attachment = PdfStorageService.getPdfAttachment(pdfId);
    if (attachment == null) throw Exception('PDF not found');

    final versionFile = File(version.filePath);
    final currentFile = File(attachment.filePath);

    await versionFile.copy(currentFile.path);
  }

  /// Add signature to PDF
  static Future<models.PdfSignature> addSignature({
    required int pageNumber,
    required double x,
    required double y,
    required double width,
    required double height,
    String? signerName,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) throw Exception('No signature image selected');

    final appDir = await getApplicationDocumentsDirectory();
    final signaturesDir = Directory('${appDir.path}/$_signaturesDirName');
    if (!await signaturesDir.exists()) {
      await signaturesDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final signaturePath = '${signaturesDir.path}/signature_$timestamp.png';
    await File(pickedFile.path).copy(signaturePath);

    return models.PdfSignature(
      pageNumber: pageNumber,
      imagePath: signaturePath,
      x: x,
      y: y,
      width: width,
      height: height,
      signerName: signerName,
    );
  }

  /// Add image to PDF
  static Future<models.PdfImageElement> addImage({
    required int pageNumber,
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) throw Exception('No image selected');

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/pdf_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imagePath = '${imagesDir.path}/image_$timestamp.png';
    await File(pickedFile.path).copy(imagePath);

    return models.PdfImageElement(
      pageNumber: pageNumber,
      imagePath: imagePath,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  /// Compare two PDF versions
  static Future<Map<String, dynamic>> compareVersions(String pdfId, int version1, int version2) async {
    final versions = await getVersions(pdfId);
    final v1 = versions.firstWhere((v) => v.versionNumber == version1);
    final v2 = versions.firstWhere((v) => v.versionNumber == version2);

    final file1 = File(v1.filePath);
    final file2 = File(v2.filePath);

    final bytes1 = await file1.readAsBytes();
    final bytes2 = await file2.readAsBytes();

    final doc1 = sf_pdf.PdfDocument(inputBytes: bytes1);
    final doc2 = sf_pdf.PdfDocument(inputBytes: bytes2);

    try {
      final extractor1 = sf_pdf.PdfTextExtractor(doc1);
      final extractor2 = sf_pdf.PdfTextExtractor(doc2);

      final text1 = extractor1.extractText();
      final text2 = extractor2.extractText();

      return {
        'version1': version1,
        'version2': version2,
        'pageCountDiff': doc2.pages.count - doc1.pages.count,
        'sizeDiff': v2.fileSize - v1.fileSize,
        'textLength1': text1.length,
        'textLength2': text2.length,
        'textDiff': text2.length - text1.length,
      };
    } finally {
      doc1.dispose();
      doc2.dispose();
    }
  }

  // Helper methods
  static sf_pdf.PdfColor _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    return sf_pdf.PdfColor(r, g, b);
  }

  /// Grammar check (basic offline implementation)
  static List<String> checkGrammar(String text) {
    final suggestions = <String>[];

    // Basic grammar checks
    if (text.contains('  ')) {
      suggestions.add('Multiple spaces detected');
    }
    if (!text.trim().endsWith('.') && !text.trim().endsWith('!') && !text.trim().endsWith('?')) {
      suggestions.add('Consider adding punctuation at the end');
    }
    if (text.split(' ').any((word) => word.length > 20)) {
      suggestions.add('Very long words detected - check for typos');
    }

    return suggestions;
  }

  /// Generate summary of PDF
  static Future<String> generateSummary(String pdfId, {int maxLength = 500}) async {
    final text = await extractPlainText(pdfId);
    
    if (text.isEmpty) return '';

    final sentences = text.split(RegExp(r'[.!?]\s+'));
    final buffer = StringBuffer();
    int currentLength = 0;

    for (var sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;

      if (currentLength + trimmed.length > maxLength) break;

      buffer.write(trimmed);
      buffer.write('. ');
      currentLength += trimmed.length + 2;
    }

    return buffer.toString().trim();
  }
}
