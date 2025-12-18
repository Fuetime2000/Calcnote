import 'package:flutter/material.dart';

/// Screen that shows comprehensive guide on how to use the CalcNote app
class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use CalcNote'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Section
          _buildWelcomeCard(theme),
          const SizedBox(height: 24),
          
          // Quick Start
          _buildSectionTitle('🚀 Quick Start', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.add_circle,
            title: 'Create a Note',
            description: 'Tap the + (plus) button at the bottom right to create a new note.',
            steps: [
              'Tap the floating + button',
              'Enter your note title and content',
              'Your note is auto-saved every 2 seconds',
            ],
          ),
          const SizedBox(height: 16),
          
          // Calculator Feature
          _buildSectionTitle('🧮 Smart Calculator', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.calculate,
            title: 'Use Calculator in Notes',
            description: 'Type calculations directly in the top calculator bar.',
            steps: [
              'Type: 25 + 30 * 2 in the calculator bar',
              'Result shows instantly: = 85',
              'Press Enter to add result to a new note',
              'Or use the calculator icon for full calculator',
            ],
            examples: [
              '50 + 30 = 80',
              '100 * 0.15 = 15',
              'sqrt(144) = 12',
              '2^8 = 256',
            ],
          ),
          const SizedBox(height: 16),
          
          // Bottom Navigation
          _buildSectionTitle('📱 Navigation Tabs', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.notes,
            title: 'Notes Tab',
            description: 'View all your notes',
            steps: [
              'Shows all active notes',
              'Search notes using the search icon',
              'Tap any note to open and edit',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.star,
            title: 'Starred Tab',
            description: 'View pinned/important notes',
            steps: [
              'Shows only pinned notes',
              'Pin notes using the pin icon in editor',
              'Quick access to important notes',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.archive,
            title: 'Archive Tab',
            description: 'View archived notes',
            steps: [
              'Shows archived notes',
              'Archive notes from the editor menu',
              'Keep notes organized',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.picture_as_pdf,
            title: 'PDFs Tab',
            description: 'View attached PDF files',
            steps: [
              'Shows all PDF attachments',
              'Attach PDFs from note editor',
              'Quick access to documents',
            ],
          ),
          const SizedBox(height: 16),
          
          // Note Editor Features
          _buildSectionTitle('✏️ Note Editor Features', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.push_pin,
            title: 'Pin Notes',
            description: 'Keep important notes at the top',
            steps: [
              'Open any note',
              'Tap the pin icon in the top bar',
              'Pinned notes appear in Starred tab',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.palette,
            title: 'Change Theme Colors',
            description: 'Customize note appearance',
            steps: [
              'Open any note',
              'Tap the palette icon',
              'Choose from beautiful themes',
              'Each note can have different colors',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.check_box,
            title: 'Create Checklists',
            description: 'Add interactive checkboxes',
            steps: [
              'Type: - [ ] Task name',
              'Creates an unchecked checkbox',
              'Type: - [x] Done task',
              'Creates a checked checkbox',
              'Tap checkboxes to toggle them',
            ],
            examples: [
              '- [ ] Buy groceries',
              '- [x] Complete homework',
              '- [ ] Call dentist',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.calculate_outlined,
            title: 'Insert Calculator Results',
            description: 'Add calculations to notes',
            steps: [
              'Open any note',
              'Tap the calculator icon in editor',
              'Enter calculation',
              'Result is inserted into note',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.picture_as_pdf,
            title: 'Attach PDFs',
            description: 'Link PDF files to notes',
            steps: [
              'Open any note',
              'Tap the PDF icon',
              'Select PDF from device',
              'PDF is attached to note',
            ],
          ),
          const SizedBox(height: 16),
          
          // AI Features
          _buildSectionTitle('🤖 AI Features', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.smart_toy,
            title: 'AI Chat Assistant',
            description: 'Get help from AI',
            steps: [
              'Tap the AI robot icon in top bar',
              'Ask questions about your notes',
              'Get smart suggestions',
              'AI helps organize and improve notes',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.auto_awesome,
            title: 'Auto-Detection',
            description: 'AI automatically detects:',
            steps: [
              '📊 Calculations in notes',
              '🏷️ Categories and tags',
              '📝 Formulas and equations',
              '💰 Sums and totals',
            ],
          ),
          const SizedBox(height: 16),
          
          // Top Menu (Three Dots)
          _buildSectionTitle('⋮ Top Menu Options', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.backup,
            title: 'Backup Notes',
            description: 'Save all notes to a file',
            steps: [
              'Tap three dots (⋮) in top right',
              'Select "Backup Notes"',
              'Backup saved to Downloads folder',
              'Use Share button to move/save elsewhere',
              'Readable text format - open in any app',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.translate,
            title: 'Translate',
            description: 'Translate notes to other languages',
            steps: [
              'Tap three dots (⋮)',
              'Select "Translate"',
              'Choose target language',
              'Get instant translation',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.lock,
            title: 'Security Settings',
            description: 'Protect your notes',
            steps: [
              'Tap three dots (⋮)',
              'Select "Security"',
              'Set up PIN or biometric lock',
              'Lock individual notes',
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            theme,
            icon: Icons.light_mode,
            title: 'Theme Options',
            description: 'Change app appearance',
            steps: [
              'Tap three dots (⋮)',
              'Choose Light Theme, Dark Theme, or Auto',
              'Auto theme follows system settings',
              'Applies to entire app',
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Feature
          _buildSectionTitle('🔍 Search Notes', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.search,
            title: 'Find Notes Quickly',
            description: 'Search through all notes',
            steps: [
              'Tap the search icon in top bar',
              'Type keywords to search',
              'Results update instantly',
              'Searches titles and content',
            ],
          ),
          const SizedBox(height: 16),
          
          // Tips & Tricks
          _buildSectionTitle('💡 Tips & Tricks', theme),
          _buildTipCard(
            theme,
            '⚡ Auto-Save',
            'Notes are automatically saved every 2 seconds while typing. No need to manually save!',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            theme,
            '📌 Pin Important Notes',
            'Pin frequently used notes to keep them at the top and in the Starred tab.',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            theme,
            '🎨 Color Code Notes',
            'Use different themes for different types of notes (work, personal, shopping, etc.).',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            theme,
            '✅ Use Checklists',
            'Create to-do lists with checkboxes for shopping, tasks, and projects.',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            theme,
            '🧮 Quick Calculations',
            'Type calculations in the top bar for instant results without opening calculator.',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            theme,
            '💾 Regular Backups',
            'Backup your notes regularly using the Backup feature in the top menu.',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            theme,
            '🔒 Secure Sensitive Notes',
            'Use the lock feature for notes containing passwords or private information.',
          ),
          const SizedBox(height: 16),
          
          // Keyboard Shortcuts
          _buildSectionTitle('⌨️ Markdown Support', theme),
          _buildFeatureCard(
            theme,
            icon: Icons.format_bold,
            title: 'Text Formatting',
            description: 'Use markdown for formatting',
            examples: [
              '# Heading 1',
              '## Heading 2',
              '**bold text**',
              '*italic text*',
              '- Bullet point',
              '1. Numbered list',
            ],
          ),
          const SizedBox(height: 24),
          
          // Footer
          _buildFooterCard(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to CalcNote!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your smart note-taking app with built-in calculator and AI features',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
    List<String>? steps,
    List<String>? examples,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (steps != null && steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (examples != null && examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Examples:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...examples.map((example) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        example,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTipCard(ThemeData theme, String title, String description) {
    return Card(
      elevation: 1,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooterCard(ThemeData theme) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.help_outline,
              size: 48,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'Need More Help?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore the app and discover more features as you use it. Every feature is designed to make note-taking easier and smarter!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
