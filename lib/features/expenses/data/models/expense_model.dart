class ExpenseModel {
  final String id;
  final String tripId;
  final String? paidBy;
  final String description;
  final double amount;
  final String? category;
  final DateTime createdAt;
  final String? payerName;
  final String? payerAvatar;

  ExpenseModel({
    required this.id,
    required this.tripId,
    required this.paidBy,
    required this.description,
    required this.amount,
    required this.category,
    required this.createdAt,
    this.payerName,
    this.payerAvatar,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      paidBy: json['paid_by'] as String?,
      description: json['description'] ?? '',
      amount: _parseAmount(json['amount']),
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      payerName: json['payer']?['full_name'],
      payerAvatar: json['payer']?['avatar_url'],
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0;
  }
}
