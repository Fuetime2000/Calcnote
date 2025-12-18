import 'package:intl/intl.dart';

/// Local AI chat service for answering questions from stored knowledge
class LocalAIChatService {
  // Knowledge base for common questions
  static final Map<String, String> _knowledgeBase = {
    // Math formulas
    'simple interest formula': 'Simple Interest = (Principal × Rate × Time) / 100',
    'compound interest formula': 'Compound Interest = P(1 + R/100)^T - P',
    'profit formula': 'Profit = Selling Price - Cost Price',
    'loss formula': 'Loss = Cost Price - Selling Price',
    'discount formula': 'Discount = Marked Price - Selling Price',
    'percentage formula': 'Percentage = (Value / Total) × 100',
    'area of circle': 'Area = π × r² (where r is radius)',
    'area of rectangle': 'Area = length × width',
    'area of triangle': 'Area = ½ × base × height',
    'perimeter of rectangle': 'Perimeter = 2(length + width)',
    'circumference of circle': 'Circumference = 2πr',
    'pythagorean theorem': 'a² + b² = c² (where c is the hypotenuse)',
    'volume of cube': 'Volume = side³',
    'volume of sphere': 'Volume = (4/3)πr³',
    'volume of cylinder': 'Volume = πr²h',
    
    // Speed, distance, time
    'speed formula': 'Speed = Distance / Time',
    'distance formula': 'Distance = Speed × Time',
    'time formula': 'Time = Distance / Speed',
    
    // Financial
    'how to calculate profit': 'Profit = Selling Price - Cost Price. If SP > CP, there is profit.',
    'how to calculate loss': 'Loss = Cost Price - Selling Price. If CP > SP, there is loss.',
    'how to calculate discount': 'Discount = Marked Price - Selling Price. Discount% = (Discount/MP) × 100',
    'how to calculate interest': 'For Simple Interest: SI = (P × R × T) / 100. For Compound Interest: CI = P(1 + R/100)^T - P',
    'what is emi': 'EMI (Equated Monthly Installment) is a fixed payment amount made by a borrower to a lender at a specified date each month.',
    'how to save money': 'Track expenses, create a budget, cut unnecessary spending, automate savings, and invest wisely.',
    'what is investment': 'Investment is allocating money with the expectation of generating income or profit over time.',
    
    // App features
    'how to use calculator': 'Type your calculation in the top bar or tap the calculator icon to open the full calculator.',
    'how to create note': 'Tap the + button at the bottom right to create a new note.',
    'how to search notes': 'Tap the search icon in the top bar and type your query.',
    'how to delete note': 'Swipe left on a note or tap the delete icon in the note editor.',
    'how to pin note': 'Tap the star icon on a note to pin it.',
    'how to backup notes': 'Go to menu (⋮) → Backup to create a backup of all your notes.',
    'how to translate': 'Go to menu (⋮) → Translate to translate between Hindi and English.',
    'how to use security': 'Go to menu (⋮) → Security to set up PIN or biometric lock.',
    'how to change theme': 'Go to menu (⋮) → Auto Theme to enable automatic dark/light mode switching.',
    
    // General knowledge - Science
    'what is gravity': 'Gravity is the force that attracts objects toward each other. On Earth, it gives weight to physical objects.',
    'speed of light': 'The speed of light in vacuum is approximately 299,792,458 meters per second (about 300,000 km/s).',
    'what is photosynthesis': 'Photosynthesis is the process by which plants use sunlight, water, and CO2 to create oxygen and energy in the form of sugar.',
    'what is atom': 'An atom is the smallest unit of matter that retains the properties of an element. It consists of protons, neutrons, and electrons.',
    'what is dna': 'DNA (Deoxyribonucleic Acid) is a molecule that carries genetic instructions for life. It has a double helix structure.',
    'boiling point of water': 'Water boils at 100°C (212°F) at sea level under standard atmospheric pressure.',
    'freezing point of water': 'Water freezes at 0°C (32°F) at standard atmospheric pressure.',
    
    // General knowledge - Geography
    'capital of india': 'New Delhi is the capital of India.',
    'largest country': 'Russia is the largest country in the world by land area.',
    'smallest country': 'Vatican City is the smallest country in the world.',
    'highest mountain': 'Mount Everest is the highest mountain in the world at 8,849 meters (29,032 feet).',
    'longest river': 'The Nile River is generally considered the longest river in the world at about 6,650 km.',
    'largest ocean': 'The Pacific Ocean is the largest ocean, covering about 46% of Earth\'s water surface.',
    
    // General knowledge - History
    'who invented telephone': 'Alexander Graham Bell is credited with inventing the telephone in 1876.',
    'who invented computer': 'Charles Babbage is known as the "father of the computer" for his mechanical computer designs in the 1800s.',
    'who invented light bulb': 'Thomas Edison is credited with inventing the practical incandescent light bulb in 1879.',
    'when did india get independence': 'India gained independence from British rule on August 15, 1947.',
    'who was first prime minister of india': 'Jawaharlal Nehru was the first Prime Minister of India.',
    
    // Technology
    'what is ai': 'AI (Artificial Intelligence) is the simulation of human intelligence by machines, especially computer systems.',
    'what is internet': 'The Internet is a global network of interconnected computers that communicate using standardized protocols.',
    'what is programming': 'Programming is the process of creating instructions that tell a computer how to perform specific tasks.',
    'what is algorithm': 'An algorithm is a step-by-step procedure or formula for solving a problem or completing a task.',
    'what is cloud computing': 'Cloud computing is the delivery of computing services over the internet, including storage, processing, and software.',
    
    // Health & Fitness
    'how much water to drink': 'Adults should drink about 2-3 liters (8-12 cups) of water per day, depending on activity level and climate.',
    'how to stay healthy': 'Eat balanced meals, exercise regularly, get 7-8 hours of sleep, stay hydrated, and manage stress.',
    'what is bmi': 'BMI (Body Mass Index) is a measure of body fat based on height and weight. BMI = weight(kg) / height(m)²',
    'benefits of exercise': 'Exercise improves cardiovascular health, strengthens muscles, boosts mood, helps weight management, and increases energy.',
    
    // Daily life
    'how to study effectively': 'Create a schedule, minimize distractions, take regular breaks, practice active recall, and get enough sleep.',
    'how to manage time': 'Prioritize tasks, set goals, avoid multitasking, use a planner, eliminate time-wasters, and take breaks.',
    'how to reduce stress': 'Exercise regularly, practice meditation, get enough sleep, talk to someone, manage time well, and take breaks.',
    'how to improve memory': 'Get enough sleep, exercise regularly, eat brain-healthy foods, stay mentally active, and practice memory techniques.',
    'how to learn faster': 'Stay focused, practice regularly, teach others, use multiple learning methods, take breaks, and stay curious.',
    
    // General help
    'what is calcnote': 'CalcNote is a smart note-taking app with built-in calculator, AI features, offline translation, and security options.',
    'what can you do': 'I can help with math formulas, general knowledge, science, history, geography, health tips, study advice, and app features!',
  };
  
  /// Get response for a query
  static String getResponse(String query, {AssistantContext? context}) {
    final lowerQuery = query.toLowerCase().trim();

    final contextualAnswer = context != null
        ? _tryRespondWithContext(context, lowerQuery)
        : null;
    if (contextualAnswer != null && contextualAnswer.isNotEmpty) {
      return contextualAnswer;
    }

    // Direct match
    if (_knowledgeBase.containsKey(lowerQuery)) {
      return _knowledgeBase[lowerQuery]!;
    }
    
    // Fuzzy match - find best matching key
    String? bestMatch;
    int bestScore = 0;
    
    for (final key in _knowledgeBase.keys) {
      final score = _calculateSimilarity(lowerQuery, key);
      if (score > bestScore && score > 50) {
        bestScore = score;
        bestMatch = key;
      }
    }
    
    if (bestMatch != null) {
      return _knowledgeBase[bestMatch]!;
    }
    
    // Category-based responses
    if (_containsAny(lowerQuery, ['hello', 'hi', 'hey', 'namaste'])) {
      return 'Hello! 👋 I\'m your CalcNote AI assistant. I can answer questions about math, science, history, geography, health, and more! What would you like to know?';
    }
    
    if (_containsAny(lowerQuery, ['thank', 'thanks', 'dhanyavad'])) {
      return 'You\'re welcome! 😊 Feel free to ask me anything else!';
    }
    
    if (_containsAny(lowerQuery, ['bye', 'goodbye', 'see you'])) {
      return 'Goodbye! 👋 Come back anytime you need help!';
    }
    
    // Math & formulas
    if (_containsAny(lowerQuery, ['formula', 'equation']) && !_containsAny(lowerQuery, ['what', 'which'])) {
      return 'I know many formulas! Try asking:\n• Simple/Compound Interest\n• Profit/Loss/Discount\n• Area & Volume (circle, rectangle, sphere, etc.)\n• Speed-Distance-Time\n• Pythagorean theorem\n\nWhat formula do you need?';
    }
    
    if (_containsAny(lowerQuery, ['calculate', 'compute', 'solve'])) {
      return 'You can type calculations directly in the calculator bar at the top! Or ask me about specific formulas and I\'ll explain them. 🧮';
    }
    
    // Science questions
    if (_containsAny(lowerQuery, ['science', 'physics', 'chemistry', 'biology'])) {
      return 'I can answer science questions! Try asking:\n• What is gravity/photosynthesis/DNA/atom?\n• Speed of light\n• Boiling/Freezing point of water\n\nWhat would you like to know?';
    }
    
    // Geography questions
    if (_containsAny(lowerQuery, ['geography', 'country', 'capital', 'continent'])) {
      return 'I can help with geography! Try asking:\n• Capital of India\n• Largest/Smallest country\n• Highest mountain\n• Longest river\n• Largest ocean\n\nWhat do you want to know?';
    }
    
    // History questions
    if (_containsAny(lowerQuery, ['history', 'invented', 'independence', 'war'])) {
      return 'I know history facts! Try asking:\n• Who invented telephone/computer/light bulb?\n• When did India get independence?\n• Who was first PM of India?\n\nWhat historical fact interests you?';
    }
    
    // Technology questions
    if (_containsAny(lowerQuery, ['technology', 'computer', 'internet', 'programming', 'ai'])) {
      return 'I can explain tech concepts! Try asking:\n• What is AI/Internet/Programming?\n• What is algorithm/cloud computing?\n\nWhat tech topic interests you?';
    }
    
    // Health questions
    if (_containsAny(lowerQuery, ['health', 'fitness', 'exercise', 'diet', 'water'])) {
      return 'I can give health tips! Try asking:\n• How much water to drink?\n• How to stay healthy?\n• What is BMI?\n• Benefits of exercise\n\nWhat health topic interests you?';
    }
    
    // Study & learning
    if (_containsAny(lowerQuery, ['study', 'learn', 'memory', 'time management', 'stress'])) {
      return 'I can help with study tips! Try asking:\n• How to study effectively?\n• How to manage time?\n• How to reduce stress?\n• How to improve memory?\n• How to learn faster?\n\nWhat would you like advice on?';
    }
    
    // App features
    if (_containsAny(lowerQuery, ['app', 'feature', 'use', 'how to'])) {
      return 'I can explain CalcNote features! Try asking:\n• How to create/delete/pin notes?\n• How to backup/translate?\n• How to use security/calculator?\n• How to change theme?\n\nWhat feature do you need help with?';
    }
    
    if (_containsAny(lowerQuery, ['help', 'what can you'])) {
      return 'I\'m a smart AI assistant! I can help with:\n\n📚 Math & Formulas\n🔬 Science Facts\n🌍 Geography\n📜 History\n💻 Technology\n💪 Health & Fitness\n📖 Study Tips\n📱 App Features\n\nJust ask me anything!';
    }
    
    // Default response with suggestions
    return 'Hmm, I\'m not sure about that specific question. But I can help with:\n\n✓ Math formulas & calculations\n✓ Science, Geography, History\n✓ Technology & Programming\n✓ Health & Study tips\n✓ CalcNote app features\n✓ Insights about your saved notes & PDFs\n\nTry asking something like:\n• "How many notes do I have?"\n• "Show my recent notes"\n• "Simple interest formula?"\n• "Largest ocean?"';
  }
  
  /// Calculate similarity between two strings (simple algorithm)
  static int _calculateSimilarity(String s1, String s2) {
    final words1 = s1.split(' ');
    final words2 = s2.split(' ');
    
    int matches = 0;
    for (final word1 in words1) {
      if (words2.any((word2) => word2.contains(word1) || word1.contains(word2))) {
        matches++;
      }
    }
    
    return (matches * 100) ~/ words1.length;
  }
  
  /// Check if text contains any keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// Get suggested questions
  static List<String> getSuggestedQuestions() {
    return [
      'How many notes do I have?',
      'Show my recent notes',
      'How many PDFs are saved?',
      'What tags am I using?',
      'What is gravity?',
      'Capital of India?',
      'How to study effectively?',
      'Simple interest formula',
      'Who invented telephone?',
      'What is photosynthesis?',
      'How to stay healthy?',
      'Speed of light',
      'Largest ocean?',
      'What is AI?',
      'How to reduce stress?',
      'Profit formula',
    ];
  }

  /// Add custom knowledge
  static void addKnowledge(String question, String answer) {
    _knowledgeBase[question.toLowerCase()] = answer;
  }

  static String? _tryRespondWithContext(AssistantContext context, String query) {
    StringBuffer? reply;

    void addSection(String title, List<String> lines) {
      if (lines.isEmpty) return;
      reply ??= StringBuffer();
      if (reply!.isNotEmpty) {
        reply!.writeln();
      }
      reply!.writeln(title);
      for (final line in lines) {
        reply!.writeln('• $line');
      }
    }

    bool wantsNotes = _containsAny(query, [
      'how many notes',
      'note count',
      'notes do i have',
      'total notes',
      'notes saved',
      'notes summary',
      'my notes',
    ]);

    bool wantsRecentNotes = _containsAny(query, [
      'recent notes',
      'latest notes',
      'last notes',
      'recent entries',
      'recent saves',
    ]);

    bool wantsTags = _containsAny(query, [
      'tags',
      'categories',
      'labels',
    ]);

    bool wantsPdfs = _containsAny(query, [
      'pdf',
      'attachment',
      'document',
      'files saved',
      'saved pdf',
    ]);

    bool wantsSummary = _containsAny(query, [
      'saved data',
      'my data',
      'storage',
      'what is saved',
      'everything saved',
      'data summary',
    ]);

    if (wantsNotes || wantsSummary) {
      final lines = <String>[];
      lines.add('Total notes: ${context.noteCount}');
      if (context.pinnedCount > 0) {
        lines.add('Pinned notes: ${context.pinnedCount}');
      }
      if (context.archivedCount > 0) {
        lines.add('Archived notes: ${context.archivedCount}');
      }
      if (context.lockedCount > 0) {
        lines.add('Locked notes: ${context.lockedCount}');
      }
      if (context.lastUpdated != null) {
        final formatted = DateFormat('dd MMM yyyy, HH:mm').format(context.lastUpdated!);
        lines.add('Last updated note: $formatted');
      }
      addSection('📝 Notes overview', lines);
    }

    if ((wantsRecentNotes || wantsSummary) && context.recentNoteTitles.isNotEmpty) {
      addSection(
        '🗂️ Recent notes',
        context.recentNoteTitles.map((title) => title).toList(),
      );
    }

    if ((wantsTags || wantsSummary) && context.tags.isNotEmpty) {
      final topTags = context.tags.take(10).toList();
      addSection('🏷️ Tags in use', [topTags.join(', ')]);
    }

    if ((wantsPdfs || wantsSummary) && context.pdfCount >= 0) {
      final lines = <String>['Total PDFs saved: ${context.pdfCount}'];
      if (context.recentPdfTitles.isNotEmpty) {
        lines.add('Recent PDFs: ${context.recentPdfTitles.join(', ')}');
      }
      addSection('📄 PDF library', lines);
    }

    if (reply != null) {
      return reply!.toString().trim();
    }

    return null;
  }
}

/// Context passed to the AI assistant for answering app-specific queries.
class AssistantContext {
  final int noteCount;
  final int pinnedCount;
  final int archivedCount;
  final int lockedCount;
  final List<String> recentNoteTitles;
  final DateTime? lastUpdated;
  final Set<String> tags;
  final int pdfCount;
  final List<String> recentPdfTitles;

  const AssistantContext({
    required this.noteCount,
    required this.pinnedCount,
    required this.archivedCount,
    required this.lockedCount,
    required this.recentNoteTitles,
    required this.lastUpdated,
    required this.tags,
    required this.pdfCount,
    required this.recentPdfTitles,
  });
}
