import 'package:flutter/material.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/app_date_formatter.dart';
import '../../data/models/expense_model.dart';

class ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseListItem({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPayerAvatar(),
              const SizedBox(width: 12),
              // اطلاعات هزینه
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // توضیحات
                    Text(
                      expense.description.isNotEmpty
                          ? expense.description
                          : 'هزینه بدون توضیح',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── پرداخت‌کنند : اسم ──
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.payerName != null &&
                                    expense.payerName!.trim().isNotEmpty
                                ? '${expense.payerName} پرداخت کرده'
                                : 'پرداخت‌کننده نامشخص',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // تاریخ
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppDateFormatter.toJalali(expense.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // مبلغ + عملیات
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatMoney(expense.amount)} تومان',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'ثبت‌شده',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.successColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayerAvatar() {
    const size = 45.0;

    final hasAvatar =
        expense.payerAvatar != null && expense.payerAvatar!.trim().isNotEmpty;

    if (hasAvatar) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          expense.payerAvatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInitialAvatar(size),
        ),
      );
    }

    return _buildInitialAvatar(size);
  }

  Widget _buildInitialAvatar(double size) {
    final name = expense.payerName?.trim() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  static String _formatMoney(double value) {
    final intValue = value.round();
    final text = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;
      buffer.write(text[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}
