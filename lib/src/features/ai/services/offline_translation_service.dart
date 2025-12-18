/// Offline translation service for Hindi ↔ English
class OfflineTranslationService {
  // Common Hindi to English translations
  static final Map<String, String> _hindiToEnglish = {
    // Numbers
    'एक': 'one', 'दो': 'two', 'तीन': 'three', 'चार': 'four', 'पांच': 'five',
    'छह': 'six', 'सात': 'seven', 'आठ': 'eight', 'नौ': 'nine', 'दस': 'ten',
    'ग्यारह': 'eleven', 'बारह': 'twelve', 'बीस': 'twenty', 'तीस': 'thirty',
    'चालीस': 'forty', 'पचास': 'fifty', 'सौ': 'hundred', 'हजार': 'thousand',
    
    // Common words
    'नोट': 'note', 'गणना': 'calculation', 'योग': 'sum', 'कुल': 'total',
    'खर्च': 'expense', 'आय': 'income', 'बचत': 'savings', 'पैसा': 'money',
    'रुपये': 'rupees', 'लाभ': 'profit', 'हानि': 'loss', 'छूट': 'discount',
    'ब्याज': 'interest', 'प्रतिशत': 'percent', 'औसत': 'average',
    'मूल्य': 'price', 'लागत': 'cost', 'बिक्री': 'sale', 'खरीद': 'purchase',
    'भुगतान': 'payment', 'उधार': 'loan', 'ऋण': 'debt', 'निवेश': 'investment',
    
    // Actions
    'जोड़': 'add', 'घटाना': 'subtract', 'गुणा': 'multiply', 'भाग': 'divide',
    'खोज': 'search', 'सहेजें': 'save', 'हटाएं': 'delete', 'संपादित': 'edit',
    'बनाएं': 'create', 'खोलें': 'open', 'बंद': 'close', 'भेजें': 'send',
    'प्राप्त': 'receive', 'देखें': 'view', 'पढ़ें': 'read', 'लिखें': 'write',
    'गिनें': 'count', 'मापें': 'measure', 'तुलना': 'compare', 'चुनें': 'select',
    
    // Time
    'आज': 'today', 'कल': 'tomorrow', 'परसों': 'day after tomorrow',
    'अब': 'now', 'बाद में': 'later', 'पहले': 'before', 'बाद': 'after',
    'दिन': 'day', 'सप्ताह': 'week', 'महीना': 'month', 'साल': 'year',
    'सुबह': 'morning', 'दोपहर': 'afternoon', 'शाम': 'evening', 'रात': 'night',
    'घंटा': 'hour', 'मिनट': 'minute', 'सेकंड': 'second', 'समय': 'time',
    
    // Categories
    'अध्ययन': 'study', 'काम': 'work', 'व्यक्तिगत': 'personal',
    'याद': 'reminder', 'विचार': 'idea', 'सूची': 'list',
    'परियोजना': 'project', 'कार्य': 'task', 'लक्ष्य': 'goal',
    
    // Common phrases
    'नमस्ते': 'hello', 'धन्यवाद': 'thank you', 'कृपया': 'please',
    'हाँ': 'yes', 'नहीं': 'no', 'ठीक है': 'okay', 'अच्छा': 'good',
    'बुरा': 'bad', 'नया': 'new', 'पुराना': 'old', 'बड़ा': 'big',
    'छोटा': 'small', 'ज्यादा': 'more', 'कम': 'less', 'सभी': 'all',
    
    // School/Education
    'किताब': 'book', 'पेन': 'pen', 'पेंसिल': 'pencil', 'कागज': 'paper',
    'परीक्षा': 'exam', 'होमवर्क': 'homework', 'कक्षा': 'class', 'शिक्षक': 'teacher',
    'छात्र': 'student', 'विषय': 'subject', 'पाठ': 'lesson', 'अभ्यास': 'practice',
    
    // Food & Shopping
    'खाना': 'food', 'पानी': 'water', 'दूध': 'milk', 'चाय': 'tea',
    'खरीदारी': 'shopping', 'बाजार': 'market', 'दुकान': 'shop', 'सामान': 'goods',
    'सब्जी': 'vegetable', 'फल': 'fruit', 'अनाज': 'grain', 'मसाला': 'spice',
    
    // Family
    'परिवार': 'family', 'माता': 'mother', 'पिता': 'father', 'भाई': 'brother',
    'बहन': 'sister', 'बेटा': 'son', 'बेटी': 'daughter', 'दोस्त': 'friend',
    
    // Places
    'घर': 'home', 'कार्यालय': 'office', 'स्कूल': 'school', 'अस्पताल': 'hospital',
    'बैंक': 'bank', 'डाकघर': 'post office', 'रेस्तरां': 'restaurant', 'होटल': 'hotel',
    
    // Technology
    'फोन': 'phone', 'कंप्यूटर': 'computer', 'इंटरनेट': 'internet', 'ईमेल': 'email',
    'संदेश': 'message', 'फोटो': 'photo', 'वीडियो': 'video', 'ऐप': 'app',
    
    // Math & Calculation
    'जोड़': 'addition', 'घटाव': 'subtraction', 'गुणन': 'multiplication', 'भाजन': 'division',
    'समीकरण': 'equation', 'सूत्र': 'formula', 'उत्तर': 'answer', 'प्रश्न': 'question',
    'गणित': 'mathematics', 'संख्या': 'number', 'अंक': 'digit', 'राशि': 'amount',
  };
  
  // Common English to Hindi translations
  static final Map<String, String> _englishToHindi = {
    // Numbers
    'one': 'एक', 'two': 'दो', 'three': 'तीन', 'four': 'चार', 'five': 'पांच',
    'six': 'छह', 'seven': 'सात', 'eight': 'आठ', 'nine': 'नौ', 'ten': 'दस',
    'eleven': 'ग्यारह', 'twelve': 'बारह', 'twenty': 'बीस', 'thirty': 'तीस',
    'forty': 'चालीस', 'fifty': 'पचास', 'hundred': 'सौ', 'thousand': 'हजार',
    
    // Common words
    'note': 'नोट', 'calculation': 'गणना', 'sum': 'योग', 'total': 'कुल',
    'expense': 'खर्च', 'income': 'आय', 'savings': 'बचत', 'money': 'पैसा',
    'rupees': 'रुपये', 'profit': 'लाभ', 'loss': 'हानि', 'discount': 'छूट',
    'interest': 'ब्याज', 'percent': 'प्रतिशत', 'average': 'औसत',
    'price': 'मूल्य', 'cost': 'लागत', 'sale': 'बिक्री', 'purchase': 'खरीद',
    'payment': 'भुगतान', 'loan': 'उधार', 'debt': 'ऋण', 'investment': 'निवेश',
    
    // Actions
    'add': 'जोड़', 'subtract': 'घटाना', 'multiply': 'गुणा', 'divide': 'भाग',
    'search': 'खोज', 'save': 'सहेजें', 'delete': 'हटाएं', 'edit': 'संपादित',
    'create': 'बनाएं', 'open': 'खोलें', 'close': 'बंद', 'send': 'भेजें',
    'receive': 'प्राप्त', 'view': 'देखें', 'read': 'पढ़ें', 'write': 'लिखें',
    'count': 'गिनें', 'measure': 'मापें', 'compare': 'तुलना', 'select': 'चुनें',
    
    // Time
    'today': 'आज', 'tomorrow': 'कल', 'yesterday': 'कल', 'now': 'अब',
    'later': 'बाद में', 'before': 'पहले', 'after': 'बाद',
    'day': 'दिन', 'week': 'सप्ताह', 'month': 'महीना', 'year': 'साल',
    'morning': 'सुबह', 'afternoon': 'दोपहर', 'evening': 'शाम', 'night': 'रात',
    'hour': 'घंटा', 'minute': 'मिनट', 'second': 'सेकंड', 'time': 'समय',
    
    // Categories
    'study': 'अध्ययन', 'work': 'काम', 'personal': 'व्यक्तिगत',
    'reminder': 'याद', 'idea': 'विचार', 'list': 'सूची',
    'project': 'परियोजना', 'task': 'कार्य', 'goal': 'लक्ष्य',
    
    // Common phrases
    'hello': 'नमस्ते', 'thank you': 'धन्यवाद', 'please': 'कृपया',
    'yes': 'हाँ', 'no': 'नहीं', 'okay': 'ठीक है', 'good': 'अच्छा',
    'bad': 'बुरा', 'new': 'नया', 'old': 'पुराना', 'big': 'बड़ा',
    'small': 'छोटा', 'more': 'ज्यादा', 'less': 'कम', 'all': 'सभी',
    
    // School/Education
    'book': 'किताब', 'pen': 'पेन', 'pencil': 'पेंसिल', 'paper': 'कागज',
    'exam': 'परीक्षा', 'homework': 'होमवर्क', 'class': 'कक्षा', 'teacher': 'शिक्षक',
    'student': 'छात्र', 'subject': 'विषय', 'lesson': 'पाठ', 'practice': 'अभ्यास',
    
    // Food & Shopping
    'food': 'खाना', 'water': 'पानी', 'milk': 'दूध', 'tea': 'चाय',
    'shopping': 'खरीदारी', 'market': 'बाजार', 'shop': 'दुकान', 'goods': 'सामान',
    'vegetable': 'सब्जी', 'fruit': 'फल', 'grain': 'अनाज', 'spice': 'मसाला',
    
    // Family
    'family': 'परिवार', 'mother': 'माता', 'father': 'पिता', 'brother': 'भाई',
    'sister': 'बहन', 'son': 'बेटा', 'daughter': 'बेटी', 'friend': 'दोस्त',
    
    // Places
    'home': 'घर', 'office': 'कार्यालय', 'school': 'स्कूल', 'hospital': 'अस्पताल',
    'bank': 'बैंक', 'restaurant': 'रेस्तरां', 'hotel': 'होटल',
    
    // Technology
    'phone': 'फोन', 'computer': 'कंप्यूटर', 'internet': 'इंटरनेट', 'email': 'ईमेल',
    'message': 'संदेश', 'photo': 'फोटो', 'video': 'वीडियो', 'app': 'ऐप',
    
    // Math & Calculation
    'addition': 'जोड़', 'subtraction': 'घटाव', 'multiplication': 'गुणन', 'division': 'भाजन',
    'equation': 'समीकरण', 'formula': 'सूत्र', 'answer': 'उत्तर', 'question': 'प्रश्न',
    'mathematics': 'गणित', 'number': 'संख्या', 'digit': 'अंक', 'amount': 'राशि',
  };
  
  /// Translate text from Hindi to English
  static String translateHindiToEnglish(String text) {
    String result = text;
    
    _hindiToEnglish.forEach((hindi, english) {
      result = result.replaceAll(hindi, english);
    });
    
    return result;
  }
  
  /// Translate text from English to Hindi
  static String translateEnglishToHindi(String text) {
    String result = text.toLowerCase();
    
    _englishToHindi.forEach((english, hindi) {
      result = result.replaceAll(english, hindi);
    });
    
    return result;
  }
  
  /// Auto-detect language and translate
  static String autoTranslate(String text) {
    // Simple detection: if contains Devanagari script, it's Hindi
    final hindiPattern = RegExp(r'[\u0900-\u097F]');
    
    if (hindiPattern.hasMatch(text)) {
      return translateHindiToEnglish(text);
    } else {
      return translateEnglishToHindi(text);
    }
  }
  
  /// Translate specific word
  static String? translateWord(String word, {bool toHindi = false}) {
    if (toHindi) {
      return _englishToHindi[word.toLowerCase()];
    } else {
      return _hindiToEnglish[word];
    }
  }
  
  /// Get all available translations
  static Map<String, String> getAllTranslations({bool hindiToEnglish = true}) {
    return hindiToEnglish ? _hindiToEnglish : _englishToHindi;
  }
}
