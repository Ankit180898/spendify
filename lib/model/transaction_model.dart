class TransactionModel {
  final String userId;
  final double amount;
  final String description;
  final String type; // income or expense
  final String category;
  final DateTime date;

  TransactionModel({
    required this.userId,
    required this.amount,
    required this.description,
    required this.type,
    required this.category,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      userId: json['id'],
      amount: json['amount'],
      description: json['description'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      category: json['category'],
    );
  }
}
