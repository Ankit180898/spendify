class SmsTransaction {
  final String rawMessage;
  final double amount;
  final String type; // 'expense' or 'income'
  final String merchant;
  final String category;
  final DateTime date;
  bool isSelected;

  SmsTransaction({
    required this.rawMessage,
    required this.amount,
    required this.type,
    required this.merchant,
    required this.category,
    required this.date,
    this.isSelected = true,
  });
}

class SmsParserService {
  // Amount extraction: Rs.500, Rs 500, INR 500, ₹500, 500.00
  static final _amountRegex = RegExp(
    r'(?:rs\.?\s*|₹\s*|inr\s*)(\d+(?:,\d+)*(?:\.\d+)?)',
    caseSensitive: false,
  );

  // Debit keywords
  static const _debitKeywords = [
    'debited', 'debit', 'spent', 'withdrawn', 'paid', 'payment of',
    'purchase', 'transaction of', 'charged', 'deducted',
  ];

  // Credit keywords
  static const _creditKeywords = [
    'credited', 'credit', 'received', 'deposited', 'refund', 'cashback',
    'added to', 'transferred to your',
  ];

  // Merchant extraction: "at MERCHANT", "to MERCHANT", "from MERCHANT"
  static final _merchantRegex = RegExp(
    r'(?:at|to|from|for|with|via)\s+([A-Z][A-Z0-9\s&\-\.]{1,30}?)(?:\s+on\s|\s+dated|\s+ref|\s+txn|\s*[-–,.]|$)',
    caseSensitive: false,
  );

  // Date patterns
  static final _datePatterns = [
    RegExp(r'(\d{2})[/\-](\d{2})[/\-](\d{2,4})'),  // dd/mm/yy or dd-mm-yyyy
    RegExp(r'(\d{2})\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s*(\d{2,4})', caseSensitive: false),
  ];

  static const _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  // Known merchant → category mapping
  static const Map<String, String> _merchantCategories = {
    'swiggy': 'Food & Drinks',
    'zomato': 'Food & Drinks',
    'blinkit': 'Groceries',
    'bigbasket': 'Groceries',
    'zepto': 'Groceries',
    'dunzo': 'Groceries',
    'uber': 'Transport',
    'ola': 'Transport',
    'rapido': 'Transport',
    'irctc': 'Transport',
    'redbus': 'Transport',
    'makemytrip': 'Travel',
    'goibibo': 'Travel',
    'cleartrip': 'Travel',
    'yatra': 'Travel',
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'meesho': 'Shopping',
    'nykaa': 'Shopping',
    'ajio': 'Shopping',
    'netflix': 'Subscriptions',
    'spotify': 'Subscriptions',
    'hotstar': 'Subscriptions',
    'prime': 'Subscriptions',
    'pvr': 'Entertainment',
    'inox': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'apollo': 'Health',
    'medplus': 'Health',
    'netmeds': 'Health',
    'pharmeasy': 'Health',
    '1mg': 'Health',
    'gpay': 'Others',
    'phonepe': 'Others',
    'paytm': 'Others',
    'bhim': 'Others',
  };

  static List<SmsTransaction> parseAll(List<String> messages) {
    final results = <SmsTransaction>[];
    final seen = <String>{}; // deduplicate by amount+merchant

    for (final msg in messages) {
      final tx = _parse(msg);
      if (tx != null) {
        final key = '${tx.amount}_${tx.merchant}';
        if (!seen.contains(key)) {
          seen.add(key);
          results.add(tx);
        }
      }
    }

    // Most recent first
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  static SmsTransaction? _parse(String message) {
    final lower = message.toLowerCase();

    // Must contain a recognizable amount
    final amountMatch = _amountRegex.firstMatch(lower);
    if (amountMatch == null) return null;

    final rawAmt = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmt);
    if (amount == null || amount <= 0) return null;

    // Determine debit vs credit
    final isDebit = _debitKeywords.any((k) => lower.contains(k));
    final isCredit = _creditKeywords.any((k) => lower.contains(k));

    // Skip if it's purely a balance/OTP message
    if (!isDebit && !isCredit) { return null; }
    // Skip OTP / verification messages
    if (lower.contains('otp') || lower.contains('one time password') ||
        lower.contains('verification code')) { return null; }
    // Skip low-signal promotional messages
    if (lower.contains('offer') && lower.contains('cashback') && amount > 5000) { return null; }

    final type = isCredit && !isDebit ? 'income' : 'expense';

    // Extract merchant
    String merchant = 'Unknown';
    final merchantMatch = _merchantRegex.firstMatch(message);
    if (merchantMatch != null) {
      merchant = merchantMatch.group(1)!.trim();
      // Clean trailing noise
      merchant = merchant.replaceAll(RegExp(r'\s+(on|via|ref|txn).*$', caseSensitive: false), '').trim();
    }
    // Fallback: look for known merchant names in the raw message
    if (merchant == 'Unknown') {
      for (final known in _merchantCategories.keys) {
        if (lower.contains(known)) {
          merchant = known[0].toUpperCase() + known.substring(1);
          break;
        }
      }
    }

    // Infer category from merchant or message content
    final category = _inferCategory(lower, merchant.toLowerCase());

    // Extract date
    final date = _extractDate(lower) ?? DateTime.now();

    return SmsTransaction(
      rawMessage: message,
      amount: amount,
      type: type,
      merchant: merchant,
      category: category,
      date: date,
    );
  }

  static String _inferCategory(String lower, String merchantLower) {
    for (final entry in _merchantCategories.entries) {
      if (merchantLower.contains(entry.key) || lower.contains(entry.key)) {
        return entry.value;
      }
    }
    // Content-based fallback
    if (lower.contains('petrol') || lower.contains('diesel') || lower.contains('fuel')) return 'Car';
    if (lower.contains('electricity') || lower.contains('water') || lower.contains('gas') ||
        lower.contains('broadband') || lower.contains('recharge')) { return 'Bills & Fees'; }
    if (lower.contains('doctor') || lower.contains('hospital') || lower.contains('pharmacy') ||
        lower.contains('medical')) { return 'Health'; }
    if (lower.contains('school') || lower.contains('college') || lower.contains('tuition')) return 'Education';
    if (lower.contains('flight') || lower.contains('hotel') || lower.contains('resort')) return 'Travel';
    if (lower.contains('salary') || lower.contains('credit') && lower.contains('account')) return 'Others';
    return 'Others';
  }

  static DateTime? _extractDate(String lower) {
    // dd/mm/yy or dd-mm-yyyy
    final m1 = _datePatterns[0].firstMatch(lower);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!) ?? 1;
      final month = int.tryParse(m1.group(2)!) ?? 1;
      var year = int.tryParse(m1.group(3)!) ?? DateTime.now().year;
      if (year < 100) { year += 2000; }
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // dd Mon yyyy
    final m2 = _datePatterns[1].firstMatch(lower);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!) ?? 1;
      final month = _monthMap[m2.group(2)!.toLowerCase()] ?? 1;
      var year = int.tryParse(m2.group(3)!) ?? DateTime.now().year;
      if (year < 100) { year += 2000; }
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }

    return null;
  }
}
