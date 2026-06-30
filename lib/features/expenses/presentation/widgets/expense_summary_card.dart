import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsync/core/theme/app_colors.dart';

import '../providers/expense_provider.dart';

class ExpenseSummaryCard extends ConsumerWidget {
  final String tripId;

  const ExpenseSummaryCard({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(expenseTotalProvider(tripId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () async {
          context.push('/trip-expenses', extra: tripId);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // آیکون
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // متن
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'هزینه‌ها',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    totalAsync.when(
                      loading: () => const Text(
                        'در حال محاسبه جمع هزینه‌ها...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      error: (error, stackTrace) => const Text(
                        'خطا در دریافت هزینه‌ها',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.errorColor,
                        ),
                      ),
                      data: (total) => Text(
                        'جمع کل: ${_formatMoney(total)} تومان',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // فلش جزئیات
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
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
