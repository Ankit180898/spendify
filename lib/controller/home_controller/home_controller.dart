import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/categories_model.dart';
import 'package:spendify/model/transaction_model.dart';
import 'package:spendify/utils/image_constants.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  var userEmail = ''.obs;
  var userName = ''.obs;
  var totalBalance = 0.obs;
  RxDouble newBalance = RxDouble(0.0);
  var imageUrl = ''.obs;
  var transactions = <Map<String, dynamic>>[].obs;
  var transactionsList = <TransactionModel>[].obs; // Adjust the type here
  var incomeTransactions = <Map<String, dynamic>>[];
  var expenseTransactions = <Map<String, dynamic>>[];

  var isLoading = false.obs;
  var totalExpense = 0.obs;
  var totalIncome = 0.obs;
  var selectedFilter = 'weekly'.obs;

  var selectedChip = ''.obs;
  var isSelected = false.obs;
  List<Map<String, dynamic>> chartData = [];

  // pagination variables
  var currentPage = 1;
  var itemsPerPage = 10;
  @override
  void onInit() async {
    super.onInit();
    await getProfile();
    await getTransactions();
    await getBalance();
    // Filter transactions into income and expense
    filterTransactions(selectedFilter.value);
  }

  Future<void> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final user = supabaseC.auth.currentUser;
    if (user != null) {
      final response = await supabaseC.from("users").select().eq('id', user.id);

      if (response.isEmpty) {
        // Handle error
        CustomToast.errorToast("Error", 'Error fetching user profile');
        return;
      }

      final userData = response.first;
      // Save user's email, name, and balance in shared preferences
      await prefs.setString('name', userData['name']);
      await prefs.setString('email', userData['email']);

      // Update reactive variables
      userEmail.value = userData['email'];
      userName.value = userData['name'];
      totalBalance.value = userData['balance'] ?? 0.0;
      debugPrint(totalBalance.value.toString());
    } else {
      // Handle case when no user is found
      CustomToast.errorToast("Error", 'User not found');
      // You may want to navigate the user to a specific screen or handle this case differently
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

  Future<void> getBalance() async {
    final response = await supabaseC
        .from("users")
        .select('balance')
        .eq('id', supabaseC.auth.currentUser!.id)
        .single(); // Assuming there's only one row for the user's balance

    // Extract balance value from response data
    final balanceData = response;
    final balance = balanceData['balance'];

    // Update totalBalance with the fetched balance value
    totalBalance.value = balance;
  }

  Future<void> getTransactions() async {
    isLoading.value = true;
    transactions.value = await supabaseC
        .from("transactions")
        .select()
        .eq('user_id', supabaseC.auth.currentUser!.id);

    // Calculate income and expense
    calculateIncomeData();
    calculateExpensedata();

    isLoading.value = false;
  }

  var filteredTransactions = <Map<String, dynamic>>[].obs;

  // Method to filter transactions based on date
  void filterTransactions(String date) {
    final now = DateTime.now();
    switch (date) {
      case 'weekly':
        final startOfWeek = getMondayOfCurrentWeek();
        filteredTransactions.assignAll(transactions
            .where((transaction) =>
                DateTime.parse(transaction['date']).isAfter(startOfWeek))
            .toList());
        break;
      case 'monthly':
        final startOfMonth = DateTime(now.year, now.month, 1);
        filteredTransactions.assignAll(transactions
            .where((transaction) =>
                DateTime.parse(transaction['date']).isAfter(startOfMonth))
            .toList());
        break;
      // Add more cases for other date filters
      default:
        filteredTransactions.assignAll(transactions); // No filter applied
        break;
    }
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

  // Function to calculate income data for the pie chart
  void calculateIncomeData() {
    // Filter transactions of type 'income'
    incomeTransactions = transactions
        .where((transaction) => transaction['type'] == 'income')
        .toList();

    print("Income trans: $incomeTransactions");

    // Calculate total income
    totalIncome.value = incomeTransactions.fold(
        0,
        (int sum, transaction) =>
            sum + int.parse(transaction['amount'].toString()));

    print("totalIncome: $totalIncome");
  }

  void calculateExpensedata() {
    // Filter transactions of type 'income'
    expenseTransactions = transactions
        .where((transaction) => transaction['type'] == 'expense')
        .toList();
    print("expense trans: $expenseTransactions");
    // Calculate total income
    totalExpense.value = expenseTransactions.fold(
        0,
        (int sum, transaction) =>
            sum + int.parse(transaction['amount'].toString()));

    print("totalIncome: $totalIncome");
  }

  // Method to get the start of the current week (Monday)
  static DateTime getMondayOfCurrentWeek() {
    final now = DateTime.now();
    final daysSinceMonday = (now.weekday + 6) % 7;
    return now.subtract(Duration(days: daysSinceMonday));
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

  
}
