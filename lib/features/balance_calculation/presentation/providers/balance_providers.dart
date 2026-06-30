import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsync/features/expenses/presentation/providers/expense_provider.dart';
import 'package:tripsync/features/expenses/presentation/providers/expense_split_provider.dart';
import 'package:tripsync/features/expenses/presentation/providers/trip_members_provider.dart';
import '../../services/balance_calculator.dart';
import '../../data/models/settlement.dart';

final settlementsProvider =
    Provider.family<AsyncValue<List<Settlement>>, String>((ref, tripId) {
      // Providers
      final expensesAsync = ref.watch(expenseListProvider(tripId));
      final membersAsync = ref.watch(tripMembersProvider(tripId));
      final splitsAsync = ref.watch(expenseSplitsProvider(tripId));

      // Error handling
      if (expensesAsync is AsyncError ||
          membersAsync is AsyncError ||
          splitsAsync is AsyncError) {
        final error =
            expensesAsync.error ?? membersAsync.error ?? splitsAsync.error;

        final stackTrace =
            expensesAsync.stackTrace ??
            membersAsync.stackTrace ??
            splitsAsync.stackTrace;

        return AsyncValue.error(
          error ?? 'خطایی رخ داد',
          stackTrace ?? StackTrace.current,
        );
      }

      // Loading
      if (expensesAsync is AsyncLoading ||
          membersAsync is AsyncLoading ||
          splitsAsync is AsyncLoading) {
        return const AsyncValue.loading();
      }

      // Data
      final expenses = expensesAsync.value ?? [];
      final members = membersAsync.value ?? [];
      final splits = splitsAsync.value ?? [];

      if (expenses.isEmpty || members.isEmpty) {
        return const AsyncValue.data([]);
      }

      // Balance Calculation
      final settlements = BalanceCalculator.calculate(
        expenses: expenses,
        allSplits: splits,
        members: members,
      );

      return AsyncValue.data(settlements);
    });
