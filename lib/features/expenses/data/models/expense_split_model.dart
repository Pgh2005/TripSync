class ExpenseSplitModel {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final DateTime createdAt;

  // این فیلدها رو اضافه کن
  final String? fullName;
  final String? avatarUrl;

  ExpenseSplitModel({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    required this.createdAt,
    this.fullName,
    this.avatarUrl,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      id: json['id'],
      expenseId: json['expense_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      // اینجوری از join دیتابیس داده رو می‌گیریم
      fullName: json['profiles']?['full_name'],
      avatarUrl: json['profiles']?['avatar_url'],
    );
  }
}



// class ExpenseSplitModel {
//   final String id;
//   final String expenseId;
//   final String userId;
//   final double amount;
//   final DateTime createdAt;

//   ExpenseSplitModel({
//     required this.id,
//     required this.expenseId,
//     required this.userId,
//     required this.amount,
//     required this.createdAt,
//   });

//   factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
//     return ExpenseSplitModel(
//       id: json['id'],
//       expenseId: json['expense_id'],
//       userId: json['user_id'],
//       amount: (json['amount'] as num).toDouble(),
//       createdAt: DateTime.parse(json['created_at']),
//     );
//   }
// }

