import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/wallet_controller/wallet_controller.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/model/transaction_model.dart';
import 'package:spendify/utils/image_constants.dart';
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
  
  @override
  void onInit() async {
    super.onInit();
    await getProfile();
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

  // Future<void> getBalance() async {
  //   final response = await supabaseC
  //       .from("users")
  //       .select('balance')
  //       .eq('id', supabaseC.auth.currentUser!.id)
  //       .single(); // Assuming there's only one row for the user's balance
  //
  //   final balanceData = response;
  //   final balance = balanceData['balance'];
  //   totalBalance.value = balance;
  // }

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
      
      // Filter income and expense transactions
      incomeTransactions = transactions
          .where((transaction) => transaction['type'] == 'income')
          .toList();
      expenseTransactions = transactions
          .where((transaction) => transaction['type'] == 'expense')
          .toList();

      calculateBalance();
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
    totalIncome.value = incomeTransactions.fold(
        0.0,
        (double sum, transaction) =>
            sum + double.parse(transaction['amount'].toString()));

    // Calculate total expense
    totalExpense.value = expenseTransactions.fold(
        0.0,
        (double sum, transaction) =>
            sum + double.parse(transaction['amount'].toString()));

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
          
          filteredTransactions.value = yearFiltered
              .where((transaction) {
                final transDate = DateTime.parse(transaction['date']);
                return transDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
                       transDate.isBefore(endOfMonth.add(const Duration(days: 1)));
              })
              .toList();
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
      filteredTransactions.value.sort((a, b) => 
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
          
    } catch (e) {
      debugPrint('Error filtering transactions: $e');
      filteredTransactions.value = [];
    }
  }

  // Compute transactions for year only when year changes
  List<Map<String, dynamic>> _getTransactionsForYear(int year) {
    if (!_transactionsByYear.containsKey(year)) {
      _transactionsByYear[year] = transactions
          .where((t) => DateTime.parse(t['date']).year == year)
          .toList();
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
      
      _transactionsByMonth[monthKey] = transactions
          .where((t) {
            final date = DateTime.parse(t['date']);
            return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
                   date.isBefore(endOfMonth.add(const Duration(days: 1)));
          })
          .toList();
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
    filteredTransactionsByCategoryList.assignAll(transactions
        .where((transaction) => transaction['category'] == category)
        .toList());
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
    final dateTime =
        DateTime.parse(dateTimeString); // Parse the date time string
    return DateFormat("MMMM d, y").format(dateTime); // Format the date and time
  }

  // Function to get the category image based on the category name
  Widget getCategoryImage(String category, List<CategoriesModel> categoryList) {
    var matchingCategory = categoryList.firstWhere(
      (element) => element.category == category,
      orElse: () => CategoriesModel(category: '', image: ''),
    );

    if (matchingCategory.category.isNotEmpty) {
      return SvgPicture.asset(
        matchingCategory.image,
        height: 20,
        width: 20,
      );
    } else {
      return ImageConstants(colors: AppColor.secondaryExtraSoft).avatar;
    }
  }

  // Get category-wise income/expense data
  Map<String, double> calculateTotalsByCategory() {
    Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      String category = transaction['category'];
      double amount = double.parse(transaction['amount'].toString());

      // Check if the category exists in the predefined category list
      if (categoryList.any((element) => element.category == category)) {
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
}
