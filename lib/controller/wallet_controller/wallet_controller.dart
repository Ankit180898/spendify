import 'package:get/get.dart';
import 'package:spendify/main.dart';
import 'package:spendify/model/transaction_model.dart';

class TransactionController extends GetxController {
  
  
  RxList<TransactionSummary> transactions = <TransactionSummary>[].obs;

  @override
  void onInit() {
    fetchTransactions();
    super.onInit();
  }

void fetchTransactions() async {
  final response = await supabaseC.from('transactions').select();
  
  if (response.isEmpty) {
    // No data returned from the query
    throw Exception("No transactions found");
  }

  // Process the response data
  transactions.value = response
      .map((e) => TransactionSummary.fromJson(e))
      .toList()
      .cast<TransactionSummary>();
}

}
