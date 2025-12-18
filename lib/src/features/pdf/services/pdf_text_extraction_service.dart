import 'dart:io';
import 'pdf_storage_service.dart';

class PdfTextExtractionService {
  // Extract text from PDF file
  // Note: Text extraction from PDFs requires OCR or specialized libraries
  // For MVP, we'll return a placeholder
  static Future<String> extractTextFromPdf(File pdfFile) async {
    // Text extraction requires OCR or specialized PDF parsing libraries
    // This feature will be enhanced in a future update
    return 'PDF Document: ${pdfFile.path.split('/').last}\n\nNote: Text extraction requires OCR capabilities.\nThis feature will be enhanced in a future update.';
  }

  // Extract and save text for PDF attachment
  static Future<void> extractAndSaveText(String pdfId) async {
    final attachment = PdfStorageService.getPdfAttachment(pdfId);
    if (attachment == null) return;
    
    final file = File(attachment.filePath);
    if (!await file.exists()) return;
    
    final extractedText = await extractTextFromPdf(file);
    
    // Update attachment with extracted text
    final updated = attachment.copyWith(extractedText: extractedText);
    await PdfStorageService.updatePdfAttachment(updated);
  }

  // Search text in PDF
  static Future<List<SearchResult>> searchInPdf(
    String pdfId,
    String query, {
    bool caseSensitive = false,
  }) async {
    final attachment = PdfStorageService.getPdfAttachment(pdfId);
    if (attachment == null) return [];
    
    // Use cached extracted text if available
    String? text = attachment.extractedText;
    
    // Extract text if not cached
    if (text == null || text.isEmpty) {
      final file = File(attachment.filePath);
      if (!await file.exists()) return [];
      text = await extractTextFromPdf(file);
    }
    
    final List<SearchResult> results = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final searchLine = caseSensitive ? line : line.toLowerCase();
      final searchQuery = caseSensitive ? query : query.toLowerCase();
      
      if (searchLine.contains(searchQuery)) {
        // Extract page number from context
        int pageNumber = 1;
        for (int j = i; j >= 0; j--) {
          final match = RegExp(r'--- Page (\d+) ---').firstMatch(lines[j]);
          if (match != null) {
            pageNumber = int.parse(match.group(1)!);
            break;
          }
        }
        
        results.add(SearchResult(
          pdfId: pdfId,
          pageNumber: pageNumber,
          lineNumber: i + 1,
          context: line.trim(),
          matchPosition: searchLine.indexOf(searchQuery),
        ));
      }
    }
    
    return results;
  }

  // Search across multiple PDFs
  static Future<Map<String, List<SearchResult>>> searchInMultiplePdfs(
    List<String> pdfIds,
    String query, {
    bool caseSensitive = false,
  }) async {
    final Map<String, List<SearchResult>> results = {};
    
    for (var pdfId in pdfIds) {
      final pdfResults = await searchInPdf(pdfId, query, caseSensitive: caseSensitive);
      if (pdfResults.isNotEmpty) {
        results[pdfId] = pdfResults;
      }
    }
    
    return results;
  }

  // Generate summary from extracted text
  static String generateSummary(String text, {int maxLength = 500}) {
    if (text.isEmpty) return '';
    
    // Remove page markers
    final cleanText = text.replaceAll(RegExp(r'--- Page \d+ ---'), '');
    
    // Split into sentences
    final sentences = cleanText.split(RegExp(r'[.!?]\s+'));
    
    final StringBuffer summary = StringBuffer();
    int currentLength = 0;
    
    for (var sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      
      if (currentLength + trimmed.length > maxLength) break;
      
      summary.write(trimmed);
      summary.write('. ');
      currentLength += trimmed.length + 2;
    }
    
    return summary.toString().trim();
  }

  // Extract and generate summary for PDF
  static Future<String> extractAndSummarize(String pdfId, {int maxLength = 500}) async {
    final attachment = PdfStorageService.getPdfAttachment(pdfId);
    if (attachment == null) return '';
    
    String? text = attachment.extractedText;
    
    if (text == null || text.isEmpty) {
      final file = File(attachment.filePath);
      if (!await file.exists()) return '';
      text = await extractTextFromPdf(file);
    }
    
    return generateSummary(text, maxLength: maxLength);
  }

  // Get text from specific page
  // Note: Text extraction requires OCR capabilities
  static Future<String> extractTextFromPage(String pdfId, int pageNumber) async {
    final attachment = PdfStorageService.getPdfAttachment(pdfId);
    if (attachment == null) return '';
    
    final file = File(attachment.filePath);
    if (!await file.exists()) return '';
    
    // Text extraction requires OCR capabilities
    return 'Page $pageNumber\n\nText extraction requires OCR capabilities.\nThis feature will be enhanced in a future update.';
  }

  // Extract keywords from PDF text
  static List<String> extractKeywords(String text, {int limit = 20}) {
    if (text.isEmpty) return [];
    
    // Remove common words
    final commonWords = {
      'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
      'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
      'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
      'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their',
    };
    
    // Clean and split text
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3 && !commonWords.contains(word))
        .toList();
    
    // Count word frequency
    final Map<String, int> wordFreq = {};
    for (var word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }
    
    // Sort by frequency
    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.take(limit).map((e) => e.key).toList();
  }
}

class SearchResult {
  final String pdfId;
  final int pageNumber;
  final int lineNumber;
  final String context;
  final int matchPosition;

  SearchResult({
    required this.pdfId,
    required this.pageNumber,
    required this.lineNumber,
    required this.context,
    required this.matchPosition,
  });

  Map<String, dynamic> toMap() {
    return {
      'pdfId': pdfId,
      'pageNumber': pageNumber,
      'lineNumber': lineNumber,
      'context': context,
      'matchPosition': matchPosition,
    };
  }
}
