import 'package:tripsync/features/expenses/data/models/expense_model.dart';
import 'package:tripsync/features/expenses/data/models/expense_split_model.dart';
import 'package:tripsync/features/trip/data/models/trip_member_model.dart';

import '../data/models/settlement.dart';

class BalanceCalculator {
  /// ورودی:
  /// 1. لیست هزینه‌ها (که هر کدام باید شامل لیست اسپیلیت‌ها باشد)
  /// 2. لیست اعضای سفر
  static List<Settlement> calculate({
    required List<ExpenseModel> expenses,
    required List<ExpenseSplitModel>
    allSplits, // کل اسپیلیت‌های مربوط به این هزینه‌ها
    required List<TripMemberModel> members,
  }) {
    // ۱. مپ برای ذخیره تراز نهایی (Net Balance) هر کاربر
    // کلید: userId ، مقدار: تراز مالی
    Map<String, double> netBalances = {for (var m in members) m.id: 0.0};

    // ۲. تحلیل هزینه‌ها
    for (var expense in expenses) {
      final payerId = expense.paidBy;
      if (payerId == null) continue;

      // الف) به کسی که پول را پرداخت کرده، طلبکار می‌شود (طلبکار = مثبت)
      netBalances[payerId] = (netBalances[payerId] ?? 0.0) + expense.amount;

      // ب) کسانی که در این هزینه سهم داشتند، بدهکار می‌شوند (بدهکار = منفی)
      // پیدا کردن اسپیلیت‌های مربوط به این هزینه خاص
      final currentExpenseSplits = allSplits.where(
        (s) => s.expenseId == expense.id,
      );

      for (var split in currentExpenseSplits) {
        netBalances[split.userId] =
            (netBalances[split.userId] ?? 0.0) - split.amount;
      }
    }

    // ۳. جدا کردن بدهکاران و طلبکاران برای تسویه
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];

    netBalances.forEach((userId, balance) {
      if (balance < -1.0) {
        // بدهکار
        debtors.add(MapEntry(userId, balance));
      } else if (balance > 1.0) {
        // طلبکار
        creditors.add(MapEntry(userId, balance));
      }
    });

    // سورت برای بهینه‌سازی تعداد تراکنش‌ها
    debtors.sort((a, b) => a.value.compareTo(b.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    List<Settlement> settlements = [];
    int d = 0; // شاخص بدهکاران
    int c = 0; // شاخص طلبکاران

    while (d < debtors.length && c < creditors.length) {
      double debt = debtors[d].value.abs();
      double credit = creditors[c].value;

      double settledAmount = debt < credit ? debt : credit;

      // پیدا کردن نام کاربرها از لیست اعضا
      final fromMember = members.firstWhere((m) => m.id == debtors[d].key);
      final toMember = members.firstWhere((m) => m.id == creditors[c].key);

      settlements.add(
        Settlement(
          fromUserId: fromMember.id,
          fromUserName: fromMember.fullName,
          toUserId: toMember.id,
          toUserName: toMember.fullName,
          amount: settledAmount,
        ),
      );

      // بروزرسانی مقادیر باقی‌مانده
      debtors[d] = MapEntry(debtors[d].key, debtors[d].value + settledAmount);
      creditors[c] = MapEntry(
        creditors[c].key,
        creditors[c].value - settledAmount,
      );

      if (debtors[d].value.abs() < 1.0) d++;
      if (creditors[c].value.abs() < 1.0) c++;
    }

    return settlements;
  }
}
