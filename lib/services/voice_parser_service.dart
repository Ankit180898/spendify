class VoiceParseResult {
  final double? amount;
  final String? category;
  final String? description;
  final String type; // 'expense' or 'income'
  /// Confidence of the category match (0.0–1.0). Null when no category found.
  final double? categoryConfidence;

  const VoiceParseResult({
    this.amount,
    this.category,
    this.description,
    this.type = 'expense',
    this.categoryConfidence,
  });
}

class VoiceParserService {
  static const _incomeKeywords = [
    'received', 'got', 'earned', 'salary', 'income', 'credited',
    'refund', 'cashback', 'bonus', 'dividend', 'paid me', 'transferred to me',
    'freelance', 'stipend', 'pension', 'allowance',
  ];

  static const Map<String, List<String>> _categoryKeywords = {
    'Food & Drinks': [
      // category names & variations
      'food', 'foods', 'drink', 'drinks', 'eating', 'beverages',
      // venues
      'restaurant', 'cafe', 'cafeteria', 'coffee shop', 'tea shop',
      'dhaba', 'canteen', 'mess', 'bakery', 'bakeries', 'sweet shop',
      'juice bar', 'bar', 'bistro',
      // meals
      'lunch', 'dinner', 'breakfast', 'brunch', 'meal', 'meals',
      'snack', 'snacks', 'tiffin', 'thali', 'dine', 'dining',
      // items
      'coffee', 'tea', 'chai', 'juice', 'smoothie', 'water bottle',
      'pizza', 'burger', 'biryani', 'pasta', 'sandwich', 'sushi',
      'ice cream', 'dessert', 'sweets', 'mithai', 'samosa',
      // apps
      'zomato', 'swiggy', 'blinkit', 'zepto', 'dunzo',
      // verbs
      'eat', 'ate', 'ordered',
    ],
    'Groceries': [
      // category names
      'grocery', 'groceries', 'grocer',
      // items
      'vegetables', 'veggie', 'veggies', 'fruits', 'fruit',
      'milk', 'eggs', 'bread', 'rice', 'dal', 'flour', 'atta',
      'oil', 'ghee', 'sugar', 'salt', 'spices', 'masala',
      'pulses', 'lentils', 'butter', 'curd', 'yogurt', 'paneer',
      // stores
      'supermarket', 'big bazaar', 'dmart', 'reliance fresh',
      'more supermarket', 'spencer', 'nature basket',
      // local terms
      'ration', 'kirana', 'sabzi', 'mandi', 'vegetable market',
    ],
    'Transport': [
      // category names
      'transport', 'transportation', 'commute', 'commuting',
      // ride apps
      'uber', 'ola', 'rapido', 'bluemart', 'yulu', 'bounce',
      // vehicle types
      'auto', 'auto rickshaw', 'rickshaw', 'cab', 'taxi',
      'bus', 'metro', 'local train', 'ferry', 'boat',
      // terms
      'ride', 'fare', 'fare card', 'pass', 'travel pass', 'monthly pass',
      'token', 'ticket',
      // indian
      'irctc', 'local', 'share auto', 'e-rickshaw',
    ],
    'Bills & Fees': [
      // category names
      'bill', 'bills', 'fees', 'utility', 'utilities',
      // electricity/water/gas
      'electricity', 'electric', 'power', 'water', 'gas', 'lpg',
      'cylinder', 'piped gas',
      // internet/phone
      'internet', 'wifi', 'broadband', 'fiber', 'phone bill',
      'mobile bill', 'recharge', 'prepaid', 'postpaid', 'landline',
      'dth', 'cable tv',
      // operators
      'jio', 'airtel', 'vi', 'vodafone', 'idea', 'bsnl', 'tata sky',
      // housing
      'rent', 'maintenance', 'society', 'municipal', 'property tax',
      'house tax', 'emi',
    ],
    'Health': [
      // category names
      'health', 'healthcare', 'medical', 'medicine', 'medicines',
      // places
      'doctor', 'hospital', 'clinic', 'dispensary', 'pharmacy',
      'chemist', 'diagnostic', 'lab', 'pathology',
      // treatments
      'consultation', 'prescription', 'blood test', 'scan', 'mri',
      'xray', 'x-ray', 'dental', 'dentist', 'eye', 'optician',
      'surgery', 'operation',
      // fitness
      'gym', 'fitness', 'yoga', 'pilates', 'workout', 'supplement',
      'protein', 'vitamins',
      // pharmacies
      'apollo', 'medplus', 'netmeds', 'pharmeasy', 'tata 1mg', '1mg',
    ],
    'Car': [
      // category names
      'car', 'vehicle', 'automobile',
      // fuel
      'petrol', 'diesel', 'fuel', 'cng', 'ev charging',
      // maintenance
      'car service', 'service center', 'mechanic', 'garage',
      'oil change', 'tyre', 'tire', 'puncture', 'battery',
      'car wash', 'washing',
      // others
      'parking', 'toll', 'car insurance', 'vehicle insurance',
    ],
    'Shopping': [
      // category names
      'shopping', 'shop', 'shopped', 'purchase', 'purchased',
      // online stores
      'amazon', 'flipkart', 'myntra', 'meesho', 'nykaa', 'ajio',
      'snapdeal', 'tata cliq', 'bata', 'puma', 'nike',
      // items
      'clothes', 'clothing', 'shirt', 'tshirt', 't shirt', 'shoes',
      'dress', 'pants', 'jeans', 'saree', 'kurta', 'apparel', 'fashion',
      'accessories', 'bag', 'watch', 'jewellery', 'jewelry',
      'makeup', 'cosmetics', 'perfume', 'grooming',
      // terms
      'bought', 'online order', 'delivery', 'mall', 'store', 'market',
    ],
    'Entertainment': [
      // category names
      'entertainment', 'fun', 'leisure', 'recreation',
      // movies
      'movie', 'movies', 'cinema', 'film', 'pvr', 'inox', 'cinepolis',
      // streaming
      'netflix', 'hotstar', 'disney', 'prime video', 'amazon prime',
      'sony liv', 'zee5', 'apple tv', 'jio cinema',
      // live events
      'concert', 'show', 'theatre', 'play', 'event', 'sports',
      'ipl', 'cricket', 'football',
      // gaming
      'gaming', 'game', 'playstation', 'xbox', 'steam',
      // social
      'outing', 'pub', 'party', 'night out', 'club', 'lounge',
      'karaoke', 'bowling', 'arcade',
    ],
    'Investments': [
      // category names
      'investment', 'investments', 'invest', 'investing',
      // instruments
      'mutual fund', 'mf', 'stocks', 'stock', 'shares', 'share',
      'equity', 'sip', 'fixed deposit', 'fd', 'rd', 'recurring deposit',
      'nps', 'ppf', 'elss', 'bonds', 'debentures', 'gold',
      // crypto
      'crypto', 'bitcoin', 'ethereum', 'nft',
      // platforms
      'zerodha', 'groww', 'kite', 'upstox', 'angel one',
      'coin', 'small case', 'paytm money',
    ],
    'Education': [
      // category names
      'education', 'educational', 'learning', 'study', 'studies',
      // institutions
      'school', 'college', 'university', 'institute',
      // costs
      'fees', 'fee', 'tuition', 'tution', 'coaching',
      'exam fees', 'admission',
      // materials
      'books', 'book', 'stationery', 'notebooks', 'library',
      // online
      'course', 'udemy', 'coursera', 'unacademy', 'byju', 'vedantu',
      'class', 'classes', 'workshop', 'certification',
    ],
    'Travel': [
      // category names
      'travel', 'travelling', 'traveling', 'trip', 'trips',
      // accommodation
      'hotel', 'hostel', 'resort', 'airbnb', 'oyo', 'stay',
      'accommodation',
      // transport
      'flight', 'flights', 'airline', 'airport', 'bus ticket',
      'train ticket', 'plane',
      // booking
      'makemytrip', 'goibibo', 'cleartrip', 'ixigo', 'yatra',
      // holiday
      'vacation', 'holiday', 'tour', 'sightseeing', 'safari',
      // misc
      'luggage', 'baggage', 'visa', 'passport', 'insurance travel',
      'roaming', 'forex', 'currency exchange',
    ],
    'Gifts': [
      // category names
      'gift', 'gifts', 'gifting', 'present', 'presents',
      // occasions
      'birthday', 'anniversary', 'wedding', 'festival',
      'diwali', 'christmas', 'holi', 'eid',
      // charity
      'donation', 'donate', 'charity', 'temple', 'church', 'mosque',
      'offering', 'prasad', 'pooja',
    ],
    'Subscriptions': [
      // category names
      'subscription', 'subscriptions', 'subscribe', 'subscribed',
      'plan', 'monthly plan', 'annual plan', 'yearly plan',
      // services
      'spotify', 'apple', 'icloud', 'google one', 'youtube premium',
      'microsoft', 'office', 'adobe', 'canva',
      // misc
      'membership', 'annual fee', 'renewal', 'auto renewal',
    ],
    'Others': [
      'other', 'others', 'misc', 'miscellaneous', 'general',
      'random', 'else', 'different', 'various',
    ],
  };

  // Simple edit-distance for fuzzy matching short words (max 8 chars).
  static int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost]
            .reduce((x, y) => x < y ? x : y);
      }
      prev.setAll(0, curr);
    }
    return prev[b.length];
  }

  // Returns true if any word in the input is "close enough" to the keyword.
  static bool _fuzzyMatch(List<String> inputWords, String keyword) {
    final kWords = keyword.split(' ');
    if (kWords.length > 1) {
      // For multi-word keywords, check substring first
      return false; // handled by contains() in the main loop
    }
    if (keyword.length < 4) return false; // skip very short keywords
    for (final w in inputWords) {
      if (w.length < 3) continue;
      final dist = _editDistance(w, keyword);
      // Allow 1 typo for 4-5 char words, 2 typos for 6+ char words
      final threshold = keyword.length >= 6 ? 2 : 1;
      if (dist <= threshold) return true;
    }
    return false;
  }

  // Convert spoken number words to a digit string, e.g. "two thousand" → "2000"
  static String _wordsToDigits(String input) {
    const ones = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
      'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
      'nineteen': 19,
    };
    const tens = {
      'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
      'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    };
    const multipliers = {
      'hundred': 100, 'thousand': 1000,
      'lakh': 100000, 'lac': 100000, 'lacs': 100000, 'lakhs': 100000,
      'crore': 10000000, 'crores': 10000000,
    };

    final tokens = input.toLowerCase().split(RegExp(r'[\s,\-]+'));
    double current = 0;
    double result = 0;

    for (final t in tokens) {
      if (ones.containsKey(t)) {
        current += ones[t]!;
      } else if (tens.containsKey(t)) {
        current += tens[t]!;
      } else if (multipliers.containsKey(t)) {
        final m = multipliers[t]!;
        if (m == 100) {
          current *= m;
        } else {
          result += (current == 0 ? 1 : current) * m;
          current = 0;
        }
      }
    }
    result += current;

    if (result > 0) {
      // Replace the word-number portion with the digit equivalent
      final wordPattern = RegExp(
        r'\b(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|lakh|lakhs|lac|lacs|crore|crores)(?:\s+(?:zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand|lakh|lakhs|lac|lacs|crore|crores))*\b',
        caseSensitive: false,
      );
      return input.replaceFirstMapped(wordPattern, (_) => result.toInt().toString());
    }
    return input;
  }

  static VoiceParseResult parse(String text) {
    // Pre-process: convert word-numbers to digits ("two thousand" → "2000")
    final preprocessed = _wordsToDigits(text.toLowerCase().trim());
    final lower = preprocessed.toLowerCase().trim();
    final inputWords = lower.split(RegExp(r'[\s,]+'));

    // Determine type
    final isIncome = _incomeKeywords.any((k) => lower.contains(k));

    // Extract amount — supports: "200", "₹200", "rs 200", "200 rupees", "2k", "2.5k",
    // "2 lakh", "2.5 crore", "2 thousand"
    double? amount;
    final amountRegex = RegExp(
      r'(?:rs\.?\s*|₹\s*|inr\s*)?(\d+(?:,\d+)*(?:\.\d+)?)\s*(k|thousand|lakh|lakhs|lacs?|crores?|cr)?(?:\s*(?:rupees?|rs\.?|bucks?|inr))?',
      caseSensitive: false,
    );
    final match = amountRegex.firstMatch(lower);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      amount = double.tryParse(raw);
      final suffix = match.group(2)?.toLowerCase();
      if (suffix == 'k' || suffix == 'thousand') {
        amount = (amount ?? 0) * 1000;
      } else if (suffix == 'lakh' || suffix == 'lakhs' || suffix == 'lac' || suffix == 'lacs') {
        amount = (amount ?? 0) * 100000;
      } else if (suffix == 'crore' || suffix == 'crores' || suffix == 'cr') {
        amount = (amount ?? 0) * 10000000;
      }
    }

    // Detect category — exact substring (score 2) + fuzzy single-word (score 1)
    // Minimum score of 1.0 required to auto-select a category.
    // Below that the result is null so the user picks manually.
    String? category;
    double bestScore = 0;
    _categoryKeywords.forEach((cat, keywords) {
      double score = 0;
      for (final k in keywords) {
        if (lower.contains(k)) {
          // Longer keyword matches are more confident
          score += 1 + (k.length / 20);
        } else if (_fuzzyMatch(inputWords, k)) {
          score += 0.6;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        category = cat;
      }
    });

    // Only keep the category if the score is confident enough.
    // Below 1.0 means only weak fuzzy matches — let the user pick manually.
    const minScore = 1.0;
    const maxScore = 5.0;
    double? confidence;
    if (bestScore >= minScore) {
      confidence = (bestScore / maxScore).clamp(0.0, 1.0);
    } else {
      category = null;
    }

    // Build description from the cleaned-up text
    final stopWords = {
      'on', 'for', 'at', 'the', 'a', 'an', 'in', 'from', 'to', 'of',
      'spent', 'paid', 'bought', 'got', 'received', 'rupees', 'rs', 'inr',
      'bucks', 'thousand', 'hundred', 'lakh', 'lakhs', 'lac', 'lacs',
      'crore', 'crores', 'and', 'i', 'me', 'my',
    };
    final tokens = lower
        .split(RegExp(r'[\s,]+'))
        .where((w) => w.length > 1)
        .where((w) => !stopWords.contains(w))
        .where((w) => !RegExp(r'^\d').hasMatch(w))
        .toList();
    final description = tokens.isNotEmpty
        ? tokens.take(4).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')
        : null;

    return VoiceParseResult(
      amount: amount,
      category: category,
      description: description,
      type: isIncome ? 'income' : 'expense',
      categoryConfidence: confidence,
    );
  }
}
