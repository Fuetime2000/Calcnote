import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pdf_attachment_model.dart';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_attachment_card.dart';
import '../widgets/pdf_upload_options_dialog.dart';

class RecentPdfsScreen extends StatefulWidget {
  const RecentPdfsScreen({Key? key}) : super(key: key);

  @override
  State<RecentPdfsScreen> createState() => _RecentPdfsScreenState();
}

class _RecentPdfsScreenState extends State<RecentPdfsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pdfProvider = context.read<PdfProvider>();
      pdfProvider.loadLibraryPdfs();
      pdfProvider.loadRecentPdfs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _uploadToLibrary() async {
    final pdfProvider = context.read<PdfProvider>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const PdfUploadOptionsDialog(),
    );

    if (result == null) {
      return;
    }

    final attachment = await pdfProvider.pickAndAttachPdf(
      noteId: PdfProvider.libraryNoteId,
      compress: result['compress'] ?? true,
      encrypt: result['encrypt'] ?? false,
      password: result['password'],
    );

    if (attachment != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${attachment.fileName}" uploaded to library')),
      );
      await pdfProvider.loadLibraryPdfs();
    } else if (pdfProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pdfProvider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Library'),
            Tab(text: 'Recent'),
          ],
        ),
        actions: [
          Consumer<PdfProvider>(
            builder: (context, pdfProvider, child) {
              return FutureBuilder<String>(
                future: pdfProvider.getTotalStorageUsed(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Storage: ${snapshot.data}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<PdfProvider>(
        builder: (context, pdfProvider, child) {
          final libraryPdfs = pdfProvider.libraryPdfs;
          final recentPdfs = pdfProvider.recentPdfs;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPdfList(
                isLoading: pdfProvider.isLoading,
                attachments: libraryPdfs,
                emptyTitle: 'No library PDFs',
                emptySubtitle: 'Upload PDFs to build your library',
                onRefresh: () => pdfProvider.loadLibraryPdfs(),
              ),
              _buildPdfList(
                isLoading: pdfProvider.isLoading,
                attachments: recentPdfs,
                emptyTitle: 'No recent PDFs',
                emptySubtitle: 'PDFs you open will appear here',
                onRefresh: () => pdfProvider.loadRecentPdfs(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: _uploadToLibrary,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPdfList({
    required bool isLoading,
    required List<PdfAttachmentModel> attachments,
    required String emptyTitle,
    required String emptySubtitle,
    required Future<void> Function() onRefresh,
  }) {
    if (isLoading && attachments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (attachments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final pdf = attachments[index];
          return PdfAttachmentCard(
            attachment: pdf,
            noteId: pdf.noteId,
            onDeleted: () async {
              await onRefresh();
            },
          );
        },
      ),
    );
  }
}
