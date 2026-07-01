import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsync/core/utils/money_formatter.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';
import 'package:tripsync/features/balance_calculation/presentation/providers/balance_providers.dart';
import '../widgets/balance_card.dart';

class BalancePage extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;

  const BalancePage({super.key, required this.tripId, required this.tripName});

  @override
  ConsumerState<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends ConsumerState<BalancePage> {
  @override
  Widget build(BuildContext context) {
    final settlementsAsync = ref.watch(settlementsProvider(widget.tripId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppPrimaryAppBar(title: 'تسویه حساب سفر'),
      body: settlementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(settlementsProvider(widget.tripId)),
        ),
        data: (settlements) {
          // ── حالت خالی ──
          if (settlements.isEmpty) {
            return _EmptyState(tripName: widget.tripName);
          }

          // ── محاسبه مجموع بدهی‌ها ──
          final totalDebt = settlements.fold<double>(
            0,
            (sum, s) => sum + s.amount,
          );

          // ── حالت عادی ──
          return Column(
            children: [
              _SummaryBanner(
                transactionCount: settlements.length,
                totalDebt: totalDebt,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: settlements.length,
                  itemBuilder: (context, index) {
                    return SettlementCard(settlement: settlements[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// بنر خلاصه
// ─────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final int transactionCount;
  final double totalDebt;

  const _SummaryBanner({
    required this.transactionCount,
    required this.totalDebt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.indigo.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'مجموع تسویه‌ها',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${totalDebt.toMoney()} تومان',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync_alt, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '$transactionCount تراکنش برای تسویه',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// حالت خالی
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String tripName;

  const _EmptyState({required this.tripName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 100,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'همه تسویه هستند! ✅',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'هیچ بدهی‌ای در سفر $tripName ثبت نشده',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// حالت خطا
// ─────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'خطا در بارگذاری',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
