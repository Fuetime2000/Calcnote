import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_storage_service.dart';
import 'pdf_attachment_card.dart';
import 'pdf_upload_options_dialog.dart';

class PdfAttachmentsList extends StatelessWidget {
  final String noteId;
  final bool showAddButton;

  const PdfAttachmentsList({
    Key? key,
    required this.noteId,
    this.showAddButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PdfProvider>(
      builder: (context, pdfProvider, child) {
        final attachments = pdfProvider.attachments;

        if (attachments.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'PDF Attachments (${attachments.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (showAddButton)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addPdf(context),
                      tooltip: 'Add PDF',
                    ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                return PdfAttachmentCard(
                  attachment: attachments[index],
                  noteId: noteId,
                  onDeleted: () {
                    // Refresh the list
                    context.read<PdfProvider>().loadPdfsForNote(noteId);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (!showAddButton) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _addPdf(context),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No PDF attachments',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _addPdf(context),
                icon: const Icon(Icons.add),
                label: const Text('Add PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPdf(BuildContext context) async {
    final pdfProvider = context.read<PdfProvider>();
    
    // Pick PDF file first
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    
    // Check if PDF is natively encrypted
    final isEncrypted = await PdfStorageService.isPdfEncrypted(file);
    
    if (!context.mounted) return;
    
    // Show options dialog
    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PdfUploadOptionsDialog(
        isNativelyEncrypted: isEncrypted,
      ),
    );

    if (options != null && context.mounted) {
      // If natively encrypted and no password provided, show error
      if (isEncrypted && (options['password'] == null || options['password'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This PDF is password-protected. Please enter the password.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final attachment = await pdfProvider.pickAndAttachPdf(
        noteId: noteId,
        compress: options['compress'] ?? true,
        encrypt: options['encrypt'] ?? false,
        password: options['password'],
        pickedFile: file,
        pickedFileName: fileName,
      );

      if (attachment != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF attached successfully')),
        );
        pdfProvider.loadPdfsForNote(noteId);
      } else if (pdfProvider.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pdfProvider.error!)),
        );
      }
    }
  }
}
