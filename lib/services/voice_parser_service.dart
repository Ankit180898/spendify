class VoiceParseResult {
  final double? amount;
  final String? category;
  final String? description;
  final String type; // 'expense' or 'income'

  const VoiceParseResult({
    this.amount,
    this.category,
    this.description,
    this.type = 'expense',
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
      'food', 'drink', 'drinks', 'restaurant', 'cafe', 'coffee', 'tea',
      'lunch', 'dinner', 'breakfast', 'meal', 'snack', 'zomato', 'swiggy',
      'blinkit', 'zepto', 'pizza', 'burger', 'biryani', 'chai', 'eat',
      'ate', 'dhaba', 'canteen', 'thali', 'dine',
    ],
    'Groceries': [
      'grocery', 'groceries', 'vegetables', 'fruits', 'milk', 'supermarket',
      'big bazaar', 'dmart', 'reliance fresh', 'vegetables', 'eggs', 'bread',
      'ration', 'kirana', 'sabzi', 'more supermarket',
    ],
    'Transport': [
      'uber', 'ola', 'rapido', 'auto', 'cab', 'taxi', 'bus', 'metro',
      'train', 'irctc', 'rickshaw', 'ride', 'commute', 'transport',
      'travel pass', 'local', 'ferry',
    ],
    'Bills & Fees': [
      'bill', 'bills', 'electricity', 'water', 'gas', 'internet', 'wifi',
      'broadband', 'jio', 'airtel', 'vi', 'bsnl', 'phone', 'recharge',
      'utility', 'dth', 'cable', 'maintenance', 'society', 'municipal',
      'rent', 'landline',
    ],
    'Health': [
      'doctor', 'hospital', 'clinic', 'medicine', 'pharmacy', 'medical',
      'health', 'diagnostic', 'blood test', 'scan', 'dental', 'gym',
      'fitness', 'yoga', 'chemist', 'apollo', 'medplus', 'netmeds',
      'pharmeasy', 'consultation',
    ],
    'Car': [
      'petrol', 'diesel', 'fuel', 'car service', 'mechanic', 'parking',
      'car insurance', 'cng', 'tyre', 'vehicle', 'oil change',
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'meesho', 'nykaa', 'ajio', 'shopping',
      'clothes', 'shirt', 'shoes', 'dress', 'pants', 'apparel', 'fashion',
      'bought', 'purchase', 'online order',
    ],
    'Entertainment': [
      'movie', 'cinema', 'pvr', 'inox', 'netflix', 'hotstar', 'prime video',
      'sony liv', 'zee5', 'concert', 'show', 'theatre', 'gaming',
      'entertainment', 'outing', 'pub', 'bar', 'party', 'night out',
    ],
    'Investments': [
      'mutual fund', 'stocks', 'shares', 'sip', 'fixed deposit', 'nps',
      'investment', 'crypto', 'bitcoin', 'zerodha', 'groww', 'kite',
      'upstox', 'invest', 'fd',
    ],
    'Education': [
      'school', 'college', 'fees', 'tuition', 'course', 'books', 'udemy',
      'coursera', 'exam fees', 'university', 'library', 'stationery',
      'coaching', 'class',
    ],
    'Travel': [
      'flight', 'hotel', 'hostel', 'airbnb', 'oyo', 'makemytrip', 'goibibo',
      'trip', 'vacation', 'holiday', 'tour', 'luggage', 'visa', 'passport',
      'bus ticket', 'train ticket', 'resort',
    ],
    'Gifts': [
      'gift', 'present', 'birthday', 'anniversary', 'wedding', 'donation',
      'charity', 'temple', 'offering',
    ],
    'Subscriptions': [
      'subscription', 'subscribe', 'spotify', 'apple', 'google one',
      'youtube premium', 'membership', 'annual fee', 'renewal',
    ],
  };

  static VoiceParseResult parse(String text) {
    final lower = text.toLowerCase().trim();

    // Determine type
    final isIncome = _incomeKeywords.any((k) => lower.contains(k));

    // Extract amount — supports: "200", "₹200", "rs 200", "200 rupees", "2k", "2.5k"
    double? amount;
    final amountRegex = RegExp(
      r'(?:rs\.?\s*|₹\s*|inr\s*)?(\d+(?:,\d+)*(?:\.\d+)?)\s*(k|thousand)?(?:\s*(?:rupees?|rs\.?|bucks?|inr))?',
      caseSensitive: false,
    );
    final match = amountRegex.firstMatch(lower);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      amount = double.tryParse(raw);
      final suffix = match.group(2)?.toLowerCase();
      if (suffix == 'k' || suffix == 'thousand') {
        amount = (amount ?? 0) * 1000;
      }
    }

    // Detect category by scoring keywords
    String? category;
    int bestScore = 0;
    _categoryKeywords.forEach((cat, keywords) {
      final score = keywords.where((k) => lower.contains(k)).length;
      if (score > bestScore) {
        bestScore = score;
        category = cat;
      }
    });

    // Build description from the cleaned-up text
    final stopWords = {
      'on', 'for', 'at', 'the', 'a', 'an', 'in', 'from', 'to', 'of',
      'spent', 'paid', 'bought', 'got', 'received', 'rupees', 'rs', 'inr',
      'bucks', 'thousand', 'hundred', 'and', 'i', 'me', 'my',
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
    );
  }
}
