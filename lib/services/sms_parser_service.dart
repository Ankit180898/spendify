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

  // Merchant extraction: "at/to/towards/for MERCHANT"
  static final _merchantRegex = RegExp(
    r'(?:at|to|towards)\s+([A-Za-z][A-Za-z0-9\s&\-\.]{1,30}?)(?:\s+on\s|\s+dated|\s+ref|\s+txn|\s+via|\s*[-–,.]|$)',
    caseSensitive: false,
  );

  // UPI slash format: UPI/refno/MERCHANT NAME or UPI/MERCHANT/refno
  static final _upiSlashRegex = RegExp(
    r'UPI/\d+/([A-Za-z][A-Za-z0-9\s\.\-]{2,30}?)(?:/|$)',
    caseSensitive: false,
  );

  // UPI VPA: name@bank → extract the name part
  static final _vpaRegex = RegExp(
    r'\b([A-Za-z][A-Za-z0-9\.\-]{1,25})@[a-z]{2,}',
  );

  // UPI/NEFT info field: "Info: MERCHANT/..."  or  "Remarks: MERCHANT"
  static final _infoRegex = RegExp(
    r'(?:info|remarks|narration|description|details|particulars)\s*[:\-]\s*([A-Za-z][A-Za-z0-9\s&\.\-]{2,30}?)(?:/|\||,|;|$)',
    caseSensitive: false,
  );

  // Words that are never valid merchant names
  static const _invalidMerchants = {
    'rs', 'inr', 'your', 'you', 'account', 'a/c', 'ac', 'bank', 'card',
    'the', 'this', 'our', 'upi', 'vpa', 'neft', 'imps', 'rtgs',
    'available', 'avl', 'bal', 'balance', 'amount', 'amt', 'payment',
    'transaction', 'transfer', 'money', 'fund', 'wallet', 'saving',
    'current', 'credit', 'debit', 'mr', 'mrs', 'dear', 'customer',
  };

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

  static List<SmsTransaction> parseAll(List<String> messages, {String sender = ''}) {
    final results = <SmsTransaction>[];
    final seen = <String>{};

    for (final msg in messages) {
      final tx = _parse(msg, sender: sender);
      if (tx != null) {
        final key = '${tx.amount}_${tx.merchant}';
        if (!seen.contains(key)) {
          seen.add(key);
          results.add(tx);
        }
      }
    }

    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  // Maps common Indian bank sender IDs → readable names
  static const _senderBankNames = {
    'hdfc': 'HDFC Bank', 'hdfcbk': 'HDFC Bank',
    'sbi': 'SBI', 'sbiinb': 'SBI',
    'icici': 'ICICI Bank', 'icicib': 'ICICI Bank',
    'axis': 'Axis Bank', 'axisbk': 'Axis Bank',
    'kotak': 'Kotak Bank', 'kotakb': 'Kotak Bank',
    'pnb': 'PNB', 'bob': 'Bank of Baroda',
    'canara': 'Canara Bank', 'union': 'Union Bank',
    'indus': 'IndusInd Bank', 'indusb': 'IndusInd Bank',
    'yes': 'Yes Bank', 'yesbk': 'Yes Bank',
    'idfc': 'IDFC Bank', 'idfcbk': 'IDFC Bank',
    'rbl': 'RBL Bank', 'federal': 'Federal Bank',
    'paytm': 'Paytm', 'phonepe': 'PhonePe',
    'gpay': 'Google Pay', 'amazon': 'Amazon Pay',
  };

  static String? _bankFromSender(String sender) {
    final lower = sender.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final entry in _senderBankNames.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static SmsTransaction? _parse(String message, {String sender = ''}) {
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

    // Extract merchant — try multiple strategies in priority order
    String merchant = 'Unknown';

    // 1. "at/to/towards MERCHANT" regex
    final merchantMatch = _merchantRegex.firstMatch(message);
    if (merchantMatch != null) {
      final raw = merchantMatch.group(1)!
          .replaceAll(RegExp(r'\s+(on|via|ref|txn).*$', caseSensitive: false), '')
          .trim();
      if (!_isInvalidMerchant(raw)) merchant = _toTitleCase(raw);
    }

    // 2. UPI slash format: UPI/refno/MERCHANT
    if (merchant == 'Unknown') {
      final upiMatch = _upiSlashRegex.firstMatch(message);
      if (upiMatch != null) {
        final raw = upiMatch.group(1)!.trim();
        if (!_isInvalidMerchant(raw)) merchant = _toTitleCase(raw);
      }
    }

    // 3. Info/Remarks field: "Info: MERCHANT/ref"
    if (merchant == 'Unknown') {
      final infoMatch = _infoRegex.firstMatch(message);
      if (infoMatch != null) {
        final raw = infoMatch.group(1)!.trim();
        if (!_isInvalidMerchant(raw)) merchant = _toTitleCase(raw);
      }
    }

    // 4. VPA name: extract the local part before @ (e.g. "swiggy@icici" → "Swiggy")
    if (merchant == 'Unknown') {
      final vpaMatch = _vpaRegex.firstMatch(message);
      if (vpaMatch != null) {
        final raw = vpaMatch.group(1)!.trim();
        if (!_isInvalidMerchant(raw)) {
          merchant = _toTitleCase(raw);
        }
      }
    }

    // 5. Known merchant keyword in the message
    if (merchant == 'Unknown') {
      for (final known in _merchantCategories.keys) {
        if (lower.contains(known)) {
          merchant = known[0].toUpperCase() + known.substring(1);
          break;
        }
      }
    }

    // 6. Contextual fallbacks for common transaction types
    if (merchant == 'Unknown') {
      if (lower.contains('atm') || lower.contains('cash withdrawal')) {
        merchant = 'ATM Withdrawal';
      } else if (lower.contains('emi') || lower.contains('loan')) {
        merchant = 'EMI Payment';
      } else if (lower.contains('recharge') || lower.contains('mobile recharge')) {
        merchant = 'Mobile Recharge';
      } else if (lower.contains('electricity') || lower.contains('water bill') ||
          lower.contains('broadband') || lower.contains('gas bill')) {
        merchant = 'Utility Bill';
      } else if (lower.contains('insurance')) {
        merchant = 'Insurance';
      } else if (lower.contains('salary') || lower.contains('payroll')) {
        merchant = 'Salary';
      } else if (lower.contains('neft') || lower.contains('imps') ||
          lower.contains('rtgs') || lower.contains('transfer')) {
        merchant = 'Bank Transfer';
      } else {
        // Last resort: derive bank name from SMS sender ID (e.g. "VM-HDFCBK" → "HDFC Bank")
        final bankName = _bankFromSender(sender);
        if (bankName != null) merchant = '$bankName Txn';
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
    if (lower.contains('salary') || lower.contains('payroll')) return 'Others';
    if (lower.contains('atm') || lower.contains('cash withdrawal')) return 'Others';
    if (lower.contains('emi') || lower.contains('loan')) return 'Bills & Fees';
    if (lower.contains('insurance')) return 'Bills & Fees';
    if (lower.contains('recharge')) return 'Bills & Fees';
    return 'Others';
  }

  static String _toTitleCase(String s) {
    return s.trim().split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static bool _isInvalidMerchant(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty || lower.length < 2) return true;
    if (_invalidMerchants.contains(lower)) return true;
    // Reject if it starts with a digit or is purely numeric
    if (RegExp(r'^\d').hasMatch(lower)) return true;
    // Reject common bank account noise
    if (RegExp(r'^(xx|ending|no\.|#)').hasMatch(lower)) return true;
    return false;
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
