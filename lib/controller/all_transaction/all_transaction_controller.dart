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

  // Method to filter transactions by period
  void filterTransactions(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  // Method to filter transactions by category
  void filterTransactionsByCategory(String category) {
    isSelected.value = true;
    selectedChip.value = category;
    _applyFilters();
  }

  // Applies both period and category filters together
  void _applyFilters() {
    final now = DateTime.now();
    final filter = selectedFilter.value;

    // Step 1: period filter
    List<Map<String, dynamic>> result;
    if (filter == 'weekly') {
      result = homeController.transactions.where((t) {
        final date = DateTime.parse(t['date']);
        return date.isAfter(now.subtract(const Duration(days: 7)));
      }).toList();
    } else if (filter == 'monthly') {
      result = homeController.transactions.where((t) {
        final date = DateTime.parse(t['date']);
        return date.isAfter(now.subtract(const Duration(days: 30)));
      }).toList();
    } else {
      result = List.from(homeController.transactions);
    }

    // Step 2: category filter (if active)
    if (isSelected.value && selectedChip.value.isNotEmpty) {
      result = result.where((t) => t['category'] == selectedChip.value).toList();
    }

    filteredTransactions.value = result;
  }
}
