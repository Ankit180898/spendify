import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/model/transaction_model.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  var transactionController = Get.put(TransactionController);
  var userEmail = ''.obs;
  var userName = ''.obs;
  var totalBalance = 0.0.obs;
  RxDouble newBalance = RxDouble(0.0);
  var imageUrl = ''.obs;
  var transactions = <Map<String, dynamic>>[].obs;
  var transactionsList = <TransactionModel>[].obs;
  var incomeTransactions = <Map<String, dynamic>>[];
  var expenseTransactions = <Map<String, dynamic>>[];

  var isLoading = false.obs;
  var totalExpense = 0.0.obs;
  var totalIncome = 0.0.obs;
  var selectedFilter = 'weekly'.obs;

  var selectedChip = ''.obs;
  var isSelected = false.obs;
  List<Map<String, dynamic>> chartData = [];

  // pagination variables
  var currentPage = 1;
  var itemsPerPage = 10;

  // Add these variables at the class level if not already present
  var groupedTransactions = <String, List<Map<String, dynamic>>>{}.obs;
  var limit = 10.obs; // Default limit

  // Add this variable
  var selectedYear = DateTime.now().year.obs;

  // Cache computed values
  final _transactionsByYear = <int, List<Map<String, dynamic>>>{}.obs;
  final _transactionsByMonth = <String, List<Map<String, dynamic>>>{}.obs;
  RxBool isAmountVisible = true.obs;
  var currentPeriodName = ''.obs;
  var previousPeriodName = ''.obs;
  @override
  void onInit() async {
    super.onInit();
    await getProfile();
    await fetchTotalBalanceData();
    await getTransactions();
    filterTransactions('weekly'); // Set default filter to weekly
    groupTransactionsByMonth();
  }

  Future<void> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = supabaseC.auth.currentUser;
    if (user != null) {
      final response = await supabaseC.from("users").select().eq('id', user.id);

      if (response.isEmpty) {
        CustomToast.errorToast("Error", 'Error fetching user profile');
        return;
      }

      final userData = response.first;
      await prefs.setString('name', userData['name']);
      await prefs.setString('email', userData['email']);

      userEmail.value = userData['email'];
      userName.value = userData['name'];
      totalBalance.value = (userData['balance'] ?? 0.0).toDouble();
      debugPrint(totalBalance.value.toString());
    } else {
      CustomToast.errorToast("Error", 'User not found');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await supabaseC.auth.signOut();
      CustomToast.successToast("Success", "Signed out successfully");
    } on AuthException catch (error) {
      CustomToast.errorToast("Error", error.message);
    } catch (error) {
      CustomToast.errorToast("Error", 'Unexpected error occurred');
    } finally {
      prefs.clear();
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  Future<void> getTransactions() async {
    isLoading.value = true;
    try {
      debugPrint('Fetching transactions with limit: ${limit.value}');

      final response = await supabaseC
          .from("transactions")
          .select()
          .eq('user_id', supabaseC.auth.currentUser!.id)
          .order('date', ascending: false)
          .limit(limit.value);

      transactions.value = response
          .map((transaction) {
            final parsedDate = DateTime.tryParse(transaction['date']);
            if (parsedDate == null) return null;
            transaction['parsedDate'] = parsedDate;
            return transaction;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      debugPrint('Fetched ${transactions.length} transactions');

      // Update grouped transactions
      groupedTransactions.value = groupTransactionsByMonth();

      // Filter income and expense transactions (for display only)
      incomeTransactions = transactions.where((transaction) => transaction['type'] == 'income').toList();
      expenseTransactions = transactions.where((transaction) => transaction['type'] == 'expense').toList();

      // Don't recalculate balance here since we want the total from all transactions
      // calculateBalance();
      await fetchTotalBalanceData();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      CustomToast.errorToast("Error", "Failed to fetch transactions");
    } finally {
      isLoading.value = false;
    }
  }

  // Unified method to calculate balance based on income and expenses
  void calculateBalance() {
    // Calculate total income
    totalIncome.value =
        incomeTransactions.fold(0.0, (double sum, transaction) => sum + double.parse(transaction['amount'].toString()));

    // Calculate total expense
    totalExpense.value = expenseTransactions.fold(
        0.0, (double sum, transaction) => sum + double.parse(transaction['amount'].toString()));

    // Set total balance as income - expense
    totalBalance.value = totalIncome.value - totalExpense.value;
    debugPrint("Total Balance: $totalBalance");
  }

  var filteredTransactions = <Map<String, dynamic>>[].obs;

  // Method to filter transactions based on date
  void filterTransactions(String date) {
    selectedFilter.value = date;

    try {
      // First filter by year
      var yearFiltered = transactions.where((transaction) {
        final transDate = DateTime.parse(transaction['date']);
        return transDate.year == selectedYear.value;
      }).toList();

      switch (date) {
        case 'weekly':
          // Get current month's data instead of just the week
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = DateTime(now.year, now.month + 1, 0);

          filteredTransactions.value = yearFiltered.where((transaction) {
            final transDate = DateTime.parse(transaction['date']);
            return transDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                transDate.isBefore(endOfMonth.add(const Duration(days: 1)));
          }).toList();
          break;

        case 'monthly':
          // Show all transactions for the selected year
          filteredTransactions.value = yearFiltered;
          break;

        default:
          filteredTransactions.value = yearFiltered;
          break;
      }

      // Sort transactions by date
      filteredTransactions.value.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    } catch (e) {
      debugPrint('Error filtering transactions: $e');
      filteredTransactions.value = [];
    }
  }

  // Compute transactions for year only when year changes
  List<Map<String, dynamic>> _getTransactionsForYear(int year) {
    if (!_transactionsByYear.containsKey(year)) {
      _transactionsByYear[year] = transactions.where((t) => DateTime.parse(t['date']).year == year).toList();
    }
    return _transactionsByYear[year] ?? [];
  }

  // Compute monthly transactions only when needed
  List<Map<String, dynamic>> _getTransactionsForMonth() {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';

    if (!_transactionsByMonth.containsKey(monthKey)) {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      _transactionsByMonth[monthKey] = transactions.where((t) {
        final date = DateTime.parse(t['date']);
        return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();
    }
    return _transactionsByMonth[monthKey] ?? [];
  }

  // Clear cache when transactions are updated
  void clearCache() {
    _transactionsByYear.clear();
    _transactionsByMonth.clear();
  }

  var filteredTransactionsByCategoryList = <Map<String, dynamic>>[].obs;

  // Method to filter transactions based on category
  void filterTransactionsByCategory(String category) {
    isSelected.value = true;
    selectedChip.value = category;
    filteredTransactionsByCategoryList
        .assignAll(transactions.where((transaction) => transaction['category'] == category).toList());
  }

  // Method to get the start of the current week (Monday)
  static DateTime getMondayOfCurrentWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - now.weekday + 1);
  }

  // Method to format a DateTime object to a specific format
  static String formatDate(DateTime dateTime, String format) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  // Function to parse and format date time string
  String formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString); // Parse the date time string
    return DateFormat("MMMM d, y").format(dateTime); // Format the date and time
  }

  // Function to get the category icon based on the category name
  IconData getCategoryIcon(String category, List<CategoriesModel> categoryList) {
    var matchingCategory = categoryList.firstWhere(
      (element) => element.name == category,
      orElse: () => CategoriesModel(name: category, icon: Icons.category),
    );

    return matchingCategory.icon;
  }

  // Get category-wise income/expense data
  Map<String, double> calculateTotalsByCategory() {
    Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      String category = transaction['category'];
      double amount = double.parse(transaction['amount'].toString());

      // Check if the category exists in the predefined category list
      if (categoryList.any((element) => element.name == category)) {
        if (!categoryTotals.containsKey(category)) {
          categoryTotals[category] = 0.0;
        }
        categoryTotals[category] = categoryTotals[category]! + amount;
      }
    }

    return categoryTotals;
  }

  Map<String, List<Map<String, dynamic>>> groupTransactionsByMonth() {
    final Map<String, List<Map<String, dynamic>>> monthlyTransactions = {};

    for (var transaction in transactions) {
      final parsedDate = transaction['parsedDate'];
      if (parsedDate != null) {
        String month = DateFormat('MMMM yyyy').format(parsedDate);
        monthlyTransactions.putIfAbsent(month, () => []);
        monthlyTransactions[month]!.add(transaction);
      }
    }

    debugPrint('Grouped ${monthlyTransactions.length} months of transactions');
    return monthlyTransactions;
  }

  // Add a method to load more transactions
  Future<void> loadMore() async {
    limit.value += 10; // Increase limit by 10
    await getTransactions();
  }

  // Method to filter transactions by month
  void filterTransactionsByMonth(String monthYear) {
    try {
      final parts = monthYear.split(' ');
      final month = DateFormat('MMM').parse(parts[0]).month;
      final year = int.parse(parts[1]);

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0);

      filteredTransactions.value = transactions.where((transaction) {
        final transDate = DateTime.parse(transaction['date']);
        return transDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            transDate.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();

      // Sort transactions by date
      filteredTransactions.value.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    } catch (e) {
      debugPrint('Error filtering transactions by month: $e');
      filteredTransactions.value = [];
    }
  }

  // Add this method to HomeController
  Future<void> fetchTotalBalanceData() async {
    try {
      // Get all transactions for balance calculation without pagination
      final response = await supabaseC.from("transactions").select().eq('user_id', supabaseC.auth.currentUser!.id);

      // Split into income and expense
      final allIncomeTransactions = response.where((transaction) => transaction['type'] == 'income').toList();

      final allExpenseTransactions = response.where((transaction) => transaction['type'] == 'expense').toList();

      // Calculate total income
      totalIncome.value = allIncomeTransactions.fold(
          0.0, (double sum, transaction) => sum + double.parse(transaction['amount'].toString()));

      // Calculate total expense
      totalExpense.value = allExpenseTransactions.fold(
          0.0, (double sum, transaction) => sum + double.parse(transaction['amount'].toString()));

      // Set total balance as income - expense
      totalBalance.value = totalIncome.value - totalExpense.value;
      debugPrint("Total Balance: $totalBalance");
    } catch (e) {
      debugPrint('Error fetching total balance data: $e');
    }
  }

  void toggleVisibility() {
    isAmountVisible.value = !isAmountVisible.value;
  }

  Map<String, Map<String, double>> calculateMonthlyTotals() {
    final Map<String, Map<String, double>> monthlyTotals = {};

    for (var transaction in transactions) {
      final date = DateTime.parse(transaction['date']);
      final monthKey = DateFormat('MMM yyyy').format(date);

      if (!monthlyTotals.containsKey(monthKey)) {
        monthlyTotals[monthKey] = {
          'income': 0.0,
          'expense': 0.0,
          'savings': 0.0,
        };
      }

      if (transaction['type'] == 'income') {
        monthlyTotals[monthKey]!['income'] =
            (monthlyTotals[monthKey]!['income'] ?? 0.0) + double.parse(transaction['amount'].toString());
      } else if (transaction['type'] == 'expense') {
        monthlyTotals[monthKey]!['expense'] =
            (monthlyTotals[monthKey]!['expense'] ?? 0.0) + double.parse(transaction['amount'].toString());
      }

      // Calculate savings
      monthlyTotals[monthKey]!['savings'] =
          (monthlyTotals[monthKey]!['income'] ?? 0.0) - (monthlyTotals[monthKey]!['expense'] ?? 0.0);
    }

    return monthlyTotals;
  }

// Calculate income percentage change compared to previous period
  double calculateIncomeChange() {
    Map<String, dynamic> currentPeriodIncome = getCurrentPeriodIncome();
    Map<String, dynamic> previousPeriodIncome = getPreviousPeriodIncome();

    double currentIncome = currentPeriodIncome['amount'] ?? 0.0;
    double previousIncome = previousPeriodIncome['amount'] ?? 0.0;

    if (previousIncome == 0) {
      return currentIncome > 0 ? 100.0 : 0.0; // If previous was 0 and current is > 0, it's a 100% increase
    }

    return ((currentIncome - previousIncome) / previousIncome) * 100;
  }

  double calculateExpenseChange() {
    Map<String, dynamic> currentPeriodExpense = getCurrentPeriodExpense();
    Map<String, dynamic> previousPeriodExpense = getPreviousPeriodExpense();

    double currentExpense = currentPeriodExpense['amount'] ?? 0.0;
    double previousExpense = previousPeriodExpense['amount'] ?? 0.0;

    if (previousExpense == 0) {
      return currentExpense > 0 ? 100.0 : 0.0;
    }

    return ((currentExpense - previousExpense) / previousExpense) * 100;
  }

  double calculateSavingsChange() {
    Map<String, dynamic> currentPeriodIncome = getCurrentPeriodIncome();
    Map<String, dynamic> previousPeriodIncome = getPreviousPeriodIncome();
    Map<String, dynamic> currentPeriodExpense = getCurrentPeriodExpense();
    Map<String, dynamic> previousPeriodExpense = getPreviousPeriodExpense();

    double currentSavings = (currentPeriodIncome['amount'] ?? 0.0) - (currentPeriodExpense['amount'] ?? 0.0);
    double previousSavings = (previousPeriodIncome['amount'] ?? 0.0) - (previousPeriodExpense['amount'] ?? 0.0);

    if (previousSavings == 0) {
      return currentSavings > 0 ? 100.0 : 0.0;
    }

    return ((currentSavings - previousSavings) / previousSavings.abs()) * 100;
  }

// Get current period income based on selected filter
// Get current period income based on selected filter
  Map<String, dynamic> getCurrentPeriodIncome() {
    DateTime now = DateTime.now();
    double amount = 0.0; // Ensure amount is a double
    String periodName = '';

    switch (selectedFilter.value) {
      case 'weekly':
        // Current week
        final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        periodName = 'This Week';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'income' &&
              date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      case 'monthly':
        // Current month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        periodName = 'This Month';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'income' &&
              date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfMonth.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      default:
        // Current year
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        periodName = 'This Year';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'income' &&
              date.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfYear.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;
    }

    return {'period': periodName, 'amount': amount};
  }

// Get previous period income based on selected filter
  Map<String, dynamic> getPreviousPeriodIncome() {
    DateTime now = DateTime.now();
    double amount = 0.0; // Ensure amount is a double
    String periodName = '';

    switch (selectedFilter.value) {
      case 'weekly':
        // Previous week
        final startOfLastWeek = DateTime(now.year, now.month, now.day - now.weekday + 1 - 7);
        final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
        periodName = 'Last Week';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'income' &&
              date.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfLastWeek.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      case 'monthly':
        // Previous month
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        periodName = 'Last Month';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'income' &&
              date.isAfter(startOfLastMonth.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfLastMonth.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      default:
        // Previous year
        final startOfLastYear = DateTime(now.year - 1, 1, 1);
        final endOfLastYear = DateTime(now.year - 1, 12, 31);
        periodName = 'Last Year';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'income' &&
              date.isAfter(startOfLastYear.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfLastYear.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;
    }

    return {'period': periodName, 'amount': amount};
  }

// Get current period expense based on selected filter
  Map<String, dynamic> getCurrentPeriodExpense() {
    DateTime now = DateTime.now();
    double amount = 0.0; // Ensure amount is a double
    String periodName = '';

    switch (selectedFilter.value) {
      case 'weekly':
        // Current week
        final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        periodName = 'This Week';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'expense' &&
              date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      case 'monthly':
        // Current month
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        periodName = 'This Month';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'expense' &&
              date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfMonth.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      default:
        // Current year
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        periodName = 'This Year';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'expense' &&
              date.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfYear.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;
    }

    return {'period': periodName, 'amount': amount};
  }

// Get previous period expense based on selected filter
  Map<String, dynamic> getPreviousPeriodExpense() {
    DateTime now = DateTime.now();
    double amount = 0.0; // Ensure amount is a double
    String periodName = '';

    switch (selectedFilter.value) {
      case 'weekly':
        // Previous week
        final startOfLastWeek = DateTime(now.year, now.month, now.day - now.weekday + 1 - 7);
        final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
        periodName = 'Last Week';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'expense' &&
              date.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfLastWeek.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      case 'monthly':
        // Previous month
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        periodName = 'Last Month';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'expense' &&
              date.isAfter(startOfLastMonth.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfLastMonth.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;

      default:
        // Previous year
        final startOfLastYear = DateTime(now.year - 1, 1, 1);
        final endOfLastYear = DateTime(now.year - 1, 12, 31);
        periodName = 'Last Year';

        amount = transactions.where((t) {
          final date = DateTime.parse(t['date']);
          return t['type'] == 'expense' &&
              date.isAfter(startOfLastYear.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfLastYear.add(const Duration(days: 1)));
        }).fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));
        break;
    }

    return {'period': periodName, 'amount': amount};
  }

// Get filtered data for the income vs expense chart
  List<Map<String, dynamic>> getFilteredIncomeExpenseData() {
    switch (selectedFilter.value) {
      case 'weekly':
        return getWeeklyIncomeExpenseData();
      case 'monthly':
        return getMonthlyIncomeExpenseData();
      default:
        return getYearlyIncomeExpenseData();
    }
  }

// Get weekly income/expense data
  List<Map<String, dynamic>> getWeeklyIncomeExpenseData() {
    List<Map<String, dynamic>> result = [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayName = days[i];

      // Filter transactions for this day
      final dayTransactions = transactions.where((t) {
        final date = DateTime.parse(t['date']);
        return date.year == day.year && date.month == day.month && date.day == day.day;
      }).toList();

      // Calculate income and expense for this day
      double dayIncome = dayTransactions
          .where((t) => t['type'] == 'income')
          .fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));

      double dayExpense = dayTransactions
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));

      result.add({
        'period': dayName,
        'income': dayIncome,
        'expense': dayExpense,
      });
    }

    return result;
  }

// Get monthly income/expense data
  List<Map<String, dynamic>> getMonthlyIncomeExpenseData() {
    List<Map<String, dynamic>> result = [];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final year = selectedYear.value;

    for (int month = 1; month <= 12; month++) {
      final monthName = months[month - 1];
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0);

      // Filter transactions for this month
      final monthTransactions = transactions.where((t) {
        final date = DateTime.parse(t['date']);
        return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfMonth.add(const Duration(days: 1)));
      }).toList();

      // Calculate income and expense for this month
      double monthIncome = monthTransactions
          .where((t) => t['type'] == 'income')
          .fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));

      double monthExpense = monthTransactions
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));

      result.add({
        'period': monthName,
        'income': monthIncome,
        'expense': monthExpense,
      });
    }

    return result;
  }

// Get yearly income/expense data
  List<Map<String, dynamic>> getYearlyIncomeExpenseData() {
    List<Map<String, dynamic>> result = [];
    final int currentYear = selectedYear.value;

    // Show last 5 years
    for (int i = 0; i < 5; i++) {
      int year = currentYear - i;
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31);

      // Filter transactions for this year
      final yearTransactions = transactions.where((t) {
        final date = DateTime.parse(t['date']);
        return date.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfYear.add(const Duration(days: 1)));
      }).toList();

      // Calculate income and expense for this year
      double yearIncome = yearTransactions
          .where((t) => t['type'] == 'income')
          .fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));

      double yearExpense = yearTransactions
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (sum, t) => sum + double.parse(t['amount'].toString()));

      result.add({
        'period': year.toString(),
        'income': yearIncome,
        'expense': yearExpense,
      });
    }

    return result;
  }
}
