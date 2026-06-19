import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = Supabase.instance.client;
  return ExpenseRepository(client);
});

final expenseListProvider = FutureProvider.family<List<ExpenseModel>, String>((
  ref,
  tripId,
) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getExpensesByTripId(tripId);
});

final expenseTotalProvider = FutureProvider.family<double, String>((
  ref,
  tripId,
) async {
  final expenses = await ref.watch(expenseListProvider(tripId).future);

  return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
});
