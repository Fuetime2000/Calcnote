import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:calcnote/src/features/notes/models/note_model.dart';
import 'package:calcnote/src/features/notes/providers/note_provider.dart';
import 'package:calcnote/src/features/notes/screens/home_screen.dart';
import 'package:calcnote/src/features/notes/services/note_database_service.dart';
import 'package:calcnote/src/core/theme/app_theme.dart';
import 'package:calcnote/src/features/ai/providers/ai_provider.dart';
import 'package:calcnote/src/features/pdf/models/pdf_attachment_model.dart';
import 'package:calcnote/src/features/pdf/providers/pdf_provider.dart';
import 'package:calcnote/src/features/pdf/services/pdf_storage_service.dart';
import 'package:calcnote/src/features/pdf/services/pdf_sharing_service.dart';
import 'package:calcnote/src/features/pdf/screens/pdf_viewer_screen.dart';
import 'package:calcnote/src/features/reminders/providers/reminder_provider.dart';
import 'package:calcnote/src/core/services/navigation_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  registerHiveAdapters();
  registerPdfHiveAdapters();
  
  // Initialize database service
  final databaseService = NoteDatabaseService();
  await databaseService.init();
  
  // Initialize PDF storage service
  await PdfStorageService.initialize();
  
  // Initialize PDF sharing service
  await PdfSharingService.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        Provider<NoteDatabaseService>(
          create: (_) => databaseService,
          dispose: (_, db) => db.close(),
        ),
        ChangeNotifierProvider(
          create: (context) => NoteProvider(
            databaseService: context.read<NoteDatabaseService>(),
          )..loadNotes(),
        ),
        // AI Provider for all AI features
        ChangeNotifierProvider(
          create: (context) => AIProvider(
            databaseService: context.read<NoteDatabaseService>(),
          ),
        ),
        // PDF Provider for PDF features
        ChangeNotifierProvider(
          create: (_) => PdfProvider()..initialize(),
        ),
        // Reminder Provider for reminders and notifications
        ChangeNotifierProvider(
          create: (_) => ReminderProvider()..initialize(),
        ),
      ],
      child: const CalcNoteApp(),
    ),
  );
}

class CalcNoteApp extends StatefulWidget {
  const CalcNoteApp({super.key});

  @override
  State<CalcNoteApp> createState() => _CalcNoteAppState();
}

class _CalcNoteAppState extends State<CalcNoteApp> {
  @override
  void initState() {
    super.initState();
    _listenForSharedPdfs();
  }

  void _listenForSharedPdfs() {
    // Listen for non-encrypted PDFs (already imported)
    PdfSharingService.sharedPdfStream.listen((pdf) {
      // Reload PDFs in the provider
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      pdfProvider.loadLibraryPdfs();
      
      // Navigate directly to PDF viewer
      final navigatorKey = NavigationService().navigatorKey;
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfId: pdf.id,
              noteId: pdf.noteId,
            ),
          ),
        );
      }
    });
    
    // Listen for encrypted PDFs that need password
    PdfSharingService.pendingPdfStream.listen((sharedPdf) {
      _handleEncryptedPdf(sharedPdf);
    });
  }
  
  Future<void> _handleEncryptedPdf(dynamic sharedPdf) async {
    debugPrint('Handling encrypted PDF: ${sharedPdf.fileName}');
    
    // Wait for the widget tree to be built
    await Future.delayed(const Duration(milliseconds: 800));
    
    final navigatorKey = NavigationService().navigatorKey;
    final ctx = navigatorKey.currentContext;
    
    if (ctx == null || !mounted) {
      debugPrint('No navigator context available for password dialog');
      // Retry after a longer delay
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _handleEncryptedPdf(sharedPdf);
      return;
    }
    
    debugPrint('Showing password dialog for: ${sharedPdf.fileName}');
    final passwordController = TextEditingController();
    
    // Show password dialog
    final password = await showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Password Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This PDF is password-protected. Please enter the password to open it.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              autofocus: true,
              onSubmitted: (value) {
                Navigator.pop(context, value.trim());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, passwordController.text.trim());
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
    
    if (password != null && password.isNotEmpty) {
      // Import PDF with password
      final attachment = await PdfSharingService.importSharedPdf(
        sharedPdf.file,
        password,
      );
      
      if (attachment != null) {
        // Reload PDFs in the provider
        final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
        pdfProvider.loadLibraryPdfs();
        
        // Navigate to PDF viewer
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).push(
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(
                pdfId: attachment.id,
                noteId: attachment.noteId,
              ),
            ),
          );
        }
      } else {
        // Show error
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Failed to open PDF. Incorrect password or corrupted file.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        return MaterialApp(
          title: 'CalcNote - AI Powered',
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService().navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: aiProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
