import 'package:get/get.dart';
import '../home_controller/home_controller.dart'; // Import HomeController

class AllTransactionsController extends GetxController {
  final HomeController homeController = Get.find<HomeController>(); // Access HomeController
  var filteredTransactions = <Map<String, dynamic>>[].obs; // Filtered transactions list
  var selectedFilter = 'all'.obs; // Filter for All Transactions page
  var selectedChip = ''.obs; // Selected category chip
  var isLoading = false.obs; // Loading state
  var isSelected = false.obs; // State for category selection

  @override
  void onInit() {
    super.onInit();
    loadTransactions(); // Load transactions when the controller is initialized
  }

  // Method to load transactions
  void loadTransactions() {
    isLoading.value = true;
    // Initialize filtered transactions with all transactions from HomeController
    filteredTransactions.value = homeController.transactions; 
    isLoading.value = false;
  }

  // Method to filter transactions
  void filterTransactions(String filter) {
    selectedFilter.value = filter;
    if (filter == 'all') {
      filteredTransactions.value = homeController.transactions; // Show all transactions
    } else if (filter == 'weekly') {
      // Filter for weekly transactions
      filteredTransactions.value = homeController.transactions.where((trans) {
        final String dateString = trans['date'];
        final DateTime transactionDate = DateTime.parse(dateString); // Convert String to DateTime
        return transactionDate.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).toList();
    } else if (filter == 'monthly') {
      // Filter for monthly transactions
      filteredTransactions.value = homeController.transactions.where((trans) {
        final String dateString = trans['date'];
        final DateTime transactionDate = DateTime.parse(dateString); // Convert String to DateTime
        return transactionDate.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }).toList();
    }
  }

  // Method to filter transactions by category
  void filterTransactionsByCategory(String category) {
    isSelected.value = true;
    selectedChip.value = category;
    filteredTransactions.value = homeController.transactions.where((trans) {
      return trans['category'] == category; // Assuming each transaction has a 'category' field
    }).toList();
  }
}
