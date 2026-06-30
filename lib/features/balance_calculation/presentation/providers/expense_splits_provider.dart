import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsync/features/expenses/data/models/expense_split_model.dart';
import 'package:tripsync/features/expenses/presentation/providers/expense_provider.dart';

final expenseSplitsProvider =
    FutureProvider.family<List<ExpenseSplitModel>, String>((ref, tripId) async {
      final repository = ref.watch(expenseRepositoryProvider);

      return repository.getSplitsByTripId(tripId);
    });
