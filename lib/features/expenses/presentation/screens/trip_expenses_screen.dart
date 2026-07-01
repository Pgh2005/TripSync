import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/money_formatter.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';
import 'package:tripsync/features/balance_calculation/presentation/providers/balance_providers.dart';
import 'package:tripsync/features/expenses/presentation/providers/expense_split_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_list_item.dart';

class TripExpensesScreen extends ConsumerWidget {
  final String tripId;

  const TripExpensesScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider(tripId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppPrimaryAppBar(title: 'جزئیات هزینه‌ها'),
        body: expensesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
          error: (error, stackTrace) => _ErrorState(
            message: 'خطا در دریافت هزینه‌ها',
            detail: error.toString(),
            onRetry: () async {
              final _ = await ref.refresh(expenseListProvider(tripId).future);
              final _ = await ref.refresh(expenseSplitsProvider(tripId).future);
              ref.invalidate(expenseTotalProvider(tripId));
              ref.invalidate(settlementsProvider(tripId));
            },
          ),
          data: (expenses) {
            final total = expenses.fold<double>(
              0,
              (sum, expense) => sum + expense.amount,
            );

            if (expenses.isEmpty) {
              return _EmptyState(
                onRefresh: () async {
                  final _ = await ref.refresh(
                    expenseListProvider(tripId).future,
                  );
                  final _ = await ref.refresh(
                    expenseSplitsProvider(tripId).future,
                  );
                  ref.invalidate(expenseTotalProvider(tripId));
                  ref.invalidate(settlementsProvider(tripId));
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final _ = await ref.refresh(expenseListProvider(tripId).future);
                final _ = await ref.refresh(
                  expenseSplitsProvider(tripId).future,
                );
                ref.invalidate(expenseTotalProvider(tripId));
                ref.invalidate(settlementsProvider(tripId));
              },
              color: AppColors.primaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: expenses.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ExpenseTotalHeader(
                      total: total,
                      count: expenses.length,
                      tripId: tripId,
                    );
                  }
                  final expense = expenses[index - 1];
                  return ExpenseListItem(
                    expense: expense,
                    onEdit: () {
                      context.push(
                        '/trips/${expense.tripId}/edit-expense',
                        extra: expense,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        floatingActionButton: _buildFab(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  // ── FAB — همون گرادیانت آبی ───────────────────────────────────────
  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, Color(0xFF1D4ED8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-expense', extra: tripId);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'افزودن هزینه',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ── کارت جمع کل هزینه‌ها — همون استایل hero گرادیانت ────────────────
class _ExpenseTotalHeader extends StatelessWidget {
  final double total;
  final int count;
  final String tripId;

  const _ExpenseTotalHeader({
    required this.total,
    required this.count,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, Color(0xFF1D4ED8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // دایره‌های تزئینی
          Positioned(top: -20, left: -20, child: _decorCircle(100, 0.07)),
          Positioned(bottom: -30, right: 30, child: _decorCircle(120, 0.07)),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'جمع هزینه‌های سفر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${total.toMoney()} تومان',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count هزینه ثبت شده',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () {
                  context.pushNamed(
                    'settlement',
                    pathParameters: {'tripId': tripId},
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.15,
                    ), // پس‌زمینه نیمه‌شفاف شیشه‌ای
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calculate_outlined, // یا Icons.sync_alt_rounded
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'محاسبه و تسویه حساب اعضا',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

// ── حالت خالی ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 38,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'هنوز هزینه‌ای ثبت نشده',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'بعداً می‌تونی از دکمه افزودن هزینه، خرج‌های سفر رو ثبت کنی.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.borderColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryColor,
                    size: 18,
                  ),
                  label: const Text(
                    'تلاش دوباره',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── حالت خطا ─────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.errorColor.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.errorColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'تلاش دوباره',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
