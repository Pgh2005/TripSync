class Settlement {
  final String fromUserId; // شناسه شخص بدهکار
  final String fromUserName; // نام شخص بدهکار
  final String toUserId; // شناسه شخص طلبکار
  final String toUserName; // نام شخص طلبکار
  final double amount; // مبلغ تسویه

  Settlement({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });
}
