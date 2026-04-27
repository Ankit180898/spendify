class UpiCapture {
  final double amount;
  final String type; // 'expense' or 'income'
  final String merchant;
  final String category;
  final String source; // 'PhonePe', 'GPay', 'Paytm', etc.
  final DateTime capturedAt;
  final String rawText;

  UpiCapture({
    required this.amount,
    required this.type,
    required this.merchant,
    required this.category,
    required this.source,
    required this.capturedAt,
    required this.rawText,
  });
}

class UpiNotificationService {
  UpiNotificationService._();

  static const _supportedApps = {
    'com.phonepe.app': 'PhonePe',
    'com.google.android.apps.nbu.paisa.user': 'GPay',
    'net.one97.paytm': 'Paytm',
    'in.amazon.mShop.android.shopping': 'Amazon Pay',
    'in.org.npci.upiapp': 'BHIM',
    'com.whatsapp': 'WhatsApp Pay',
    'com.dreamplug.androidapp': 'CRED',
    'com.axis.mobile': 'Axis Pay',
    'com.csam.icici.bank.imobile': 'iMobile Pay',
  };

  static final _amountRe = RegExp(
    r'(?:₹|rs\.?\s*|inr\s*)(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final _merchantRe = RegExp(
    r'(?:paid to|sent to|payment to|transferred to|to vpa|to upi)\s+([A-Za-z0-9][A-Za-z0-9\s&\-\.]{1,35}?)(?:\s*(?:via|ref|upi ref|on|for|$))',
    caseSensitive: false,
  );

  static const _debitKeywords = [
    'paid to', 'sent to', 'debited', 'deducted', 'withdrawn',
    'payment of', 'transferred to', 'you paid', 'you sent',
  ];

  static const _creditKeywords = [
    'received', 'credited', 'added', 'refund', 'cashback',
    'you received', 'money received',
  ];

  // Maps app category names (matching utils.dart categoryList) to merchant keywords
  static const _categoryKeywords = <String, List<String>>{
    'Food & Drinks': [
      'zomato', 'swiggy', 'mcdonalds', "mcdonald's", 'kfc', 'dominos',
      "domino's", 'subway', 'burger king', 'pizza hut', 'fassos', 'faasos',
      'box8', 'biryani', 'food', 'restaurant', 'cafe', 'coffee', 'starbucks',
      'chai', 'eat', 'dining', 'eatsure', 'eatfit', 'freshmenu',
    ],
    'Groceries': [
      'bigbasket', 'blinkit', 'zepto', 'grofers', 'dmart', 'd-mart',
      'reliance fresh', 'jiomart', 'supermarket', 'grocery', 'vegetables',
      'milkbasket', 'country delight', 'licious',
    ],
    'Transport': [
      'ola', 'uber', 'rapido', 'metro', 'dmrc', 'irctc', 'railway',
      'railways', 'ksrtc', 'msrtc', 'auto', 'rickshaw', 'cab', 'taxi',
      'namma yatri', 'yulu', 'bounce', 'redbus',
    ],
    'Car': [
      'petrol', 'diesel', 'fuel', 'cng', 'parking', 'fastag', 'toll',
      'hp petrol', 'indian oil', 'bharat petroleum', 'car wash',
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'meesho',
      'snapdeal', 'shopping', 'mall', 'store', 'h&m', 'zara',
      'decathlon', 'ikea', 'lifestyle', 'shoppers stop',
    ],
    'Bills & Fees': [
      'airtel', 'jio', 'bsnl', 'vodafone', 'vi', 'electricity', 'water',
      'gas', 'bill', 'recharge', 'broadband', 'postpaid', 'prepaid',
      'rent', 'maintenance', 'society', 'internet',
    ],
    'Health': [
      'pharmeasy', 'practo', 'apollo', '1mg', 'netmeds', 'hospital',
      'clinic', 'pharmacy', 'medicine', 'doctor', 'health', 'medplus',
      'healthkart', 'gym', 'yoga', 'fitness',
    ],
    'Entertainment': [
      'netflix', 'hotstar', 'disney', 'youtube', 'spotify', 'gaana',
      'pvr', 'inox', 'bookmyshow', 'movie', 'theatre', 'concert',
      'gaming', 'steam', 'jiocinema', 'sonyliv',
    ],
    'Travel': [
      'makemytrip', 'goibibo', 'cleartrip', 'indigo', 'spicejet',
      'air india', 'vistara', 'flight', 'hotel', 'airbnb', 'oyo',
      'yatra', 'mmt', 'airport',
    ],
    'Education': [
      'udemy', 'coursera', 'byju', "byju's", 'unacademy', 'vedantu',
      'school', 'college', 'university', 'tuition', 'fees', 'course',
    ],
    'Subscriptions': [
      'subscription', 'prime', 'premium', 'plan', 'membership', 'annual',
    ],
    'Investments': [
      'zerodha', 'groww', 'upstox', 'kuvera', 'mutual fund', 'sip',
      'stock', 'investment', 'trading', 'etf', 'smallcase',
    ],
    'Gifts': ['gift', 'present', 'flowers', 'bouquet', 'ferns'],
  };

  static UpiCapture? parse({
    required String packageName,
    String? title,
    String? content,
  }) {
    final appName = _supportedApps[packageName];
    if (appName == null) return null;

    // WhatsApp has many notification types; only process if it looks like a payment
    if (packageName == 'com.whatsapp') {
      final combined = '${title ?? ''} ${content ?? ''}'.toLowerCase();
      if (!combined.contains('paid') && !combined.contains('received')) return null;
    }

    final raw = '${title ?? ''} ${content ?? ''}';
    final lower = raw.toLowerCase();

    final isDebit = _debitKeywords.any((k) => lower.contains(k));
    final isCredit = _creditKeywords.any((k) => lower.contains(k));
    if (!isDebit && !isCredit) return null;

    final amount = _extractAmount(lower);
    if (amount == null || amount <= 0) return null;

    final merchant = _extractMerchant(lower, appName);
    final category = _guessCategory(merchant, lower);

    return UpiCapture(
      amount: amount,
      type: isCredit ? 'income' : 'expense',
      merchant: merchant,
      category: category,
      source: appName,
      capturedAt: DateTime.now(),
      rawText: raw,
    );
  }

  static double? _extractAmount(String text) {
    final match = _amountRe.firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '');
    return double.tryParse(raw);
  }

  static String _extractMerchant(String text, String appName) {
    final match = _merchantRe.firstMatch(text);
    if (match != null) {
      final name = match.group(1)!.trim();
      // Filter out UPI IDs (contain @) and very short strings
      if (!name.contains('@') && name.length > 2) {
        return _titleCase(name);
      }
    }
    // Fallback: return app name as merchant source
    return appName;
  }

  static String _guessCategory(String merchant, String text) {
    final combined = '${merchant.toLowerCase()} $text';
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (combined.contains(keyword)) return entry.key;
      }
    }
    return 'Others';
  }

  static String _titleCase(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static bool isSupported(String packageName) =>
      _supportedApps.containsKey(packageName);

  static Map<String, String> get supportedApps => Map.unmodifiable(_supportedApps);
}
