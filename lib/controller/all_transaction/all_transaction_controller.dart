import 'package:get/get.dart';
import '../home_controller/home_controller.dart';

class AllTransactionsController extends GetxController {
  final HomeController homeController = Get.find<HomeController>();
  var filteredTransactions = <Map<String, dynamic>>[].obs;
  var selectedFilter = 'all'.obs;
  var selectedChip = ''.obs;
  var isLoading = false.obs;
  var isSelected = false.obs;
  var typeFilter = ''.obs; // 'income', 'expense', or '' for all
  Rx<DateTime?> specificMonth = Rx<DateTime?>(null); // when set, only show that month
  Rx<DateTime?> selectedDay = Rx<DateTime?>(null);  // when set, only show that day
  var searchQuery = ''.obs;

  static const int _pageSize = 10;
  final List<Map<String, dynamic>> _allFiltered = [];
  var _displayCount = 0;
  var hasMore = false.obs;
  var _loadingMore = false;

  List<String> get uniqueCategories {
    final seen = <String>{};
    for (final t in homeController.allTransactions) {
      final cat = t['category'];
      if (cat is String && cat.isNotEmpty) seen.add(cat);
    }
    return seen.toList()..sort();
  }

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  void loadTransactions() {
    isLoading.value = true;
    _allFiltered
      ..clear()
      ..addAll(homeController.allTransactions);
    _displayCount = _pageSize;
    _commitPage();
    isLoading.value = false;
  }

  void loadMore() {
    if (!hasMore.value || _loadingMore) return;
    _loadingMore = true;
    _displayCount += _pageSize;
    _commitPage();
    _loadingMore = false; // synchronous — safe because _commitPage is sync
  }

  void filterTransactions(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  void filterByDay(DateTime day) {
    if (selectedDay.value?.year == day.year &&
        selectedDay.value?.month == day.month &&
        selectedDay.value?.day == day.day) {
      selectedDay.value = null; // tap same day to clear
    } else {
      selectedDay.value = day;
    }
    _applyFilters();
  }

  void clearDayFilter() {
    selectedDay.value = null;
    _applyFilters();
  }

  void search(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterTransactionsByCategory(String category) {
    isSelected.value = true;
    selectedChip.value = category;
    _applyFilters();
  }

  void _applyFilters() {
    final now = DateTime.now();
    final filter = selectedFilter.value;
    final month = specificMonth.value;
    final day = selectedDay.value;

    List<Map<String, dynamic>> result;
    if (day != null) {
      result = homeController.allTransactions.where((t) {
        final date = DateTime.tryParse(t['date'] ?? '');
        if (date == null) return false;
        return date.year == day.year && date.month == day.month && date.day == day.day;
      }).toList();
    } else if (month != null) {
      result = homeController.allTransactions.where((t) {
        final date = DateTime.tryParse(t['date'] ?? '');
        if (date == null) return false;
        return date.year == month.year && date.month == month.month;
      }).toList();
    } else if (filter == 'weekly') {
      result = homeController.allTransactions.where((t) {
        final date = DateTime.tryParse(t['date'] ?? '');
        if (date == null) return false;
        return date.isAfter(now.subtract(const Duration(days: 7)));
      }).toList();
    } else if (filter == 'monthly') {
      result = homeController.allTransactions.where((t) {
        final date = DateTime.tryParse(t['date'] ?? '');
        if (date == null) return false;
        return date.isAfter(now.subtract(const Duration(days: 30)));
      }).toList();
    } else {
      result = List.from(homeController.allTransactions);
    }

    if (typeFilter.value.isNotEmpty) {
      result = result.where((t) => t['type'] == typeFilter.value).toList();
    }

    if (isSelected.value && selectedChip.value.isNotEmpty) {
      result = result.where((t) => t['category'] == selectedChip.value).toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((t) {
        final desc = (t['description'] as String? ?? '').toLowerCase();
        final cat = (t['category'] as String? ?? '').toLowerCase();
        return desc.contains(q) || cat.contains(q);
      }).toList();
    }

    _allFiltered
      ..clear()
      ..addAll(result);
    _displayCount = _pageSize;
    _commitPage();
  }

  void _commitPage() {
    final end = _displayCount.clamp(0, _allFiltered.length);
    final page = _allFiltered.sublist(0, end);
    hasMore.value = end < _allFiltered.length;
    filteredTransactions.value = page; // single assignment — one Obx rebuild
  }
}
