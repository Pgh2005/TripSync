import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/features/expenses/data/models/expense_split_model.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final SupabaseClient _client;

  ExpenseRepository(this._client);

  Future<List<ExpenseModel>> getExpensesByTripId(String tripId) async {
    final response = await _client
        .from('expenses')
        .select('''
        id,
        trip_id,
        description,
        amount,
        category,
        created_at,
        paid_by,
        payer:profiles!inner(
          full_name,
          avatar_url
        )
      ''')
        .eq('trip_id', tripId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ExpenseModel.fromJson(e)).toList();
  }

  Future<void> addExpense({
    required String tripId,
    required String description,
    required double amount,
    required String paidBy,
    required DateTime date,
    required List<String> splitBetweenUserIds,
    String? category,
  }) async {
    final expenseResponse = await _client
        .from('expenses')
        .insert({
          'trip_id': tripId,
          'description': description,
          'amount': amount,
          'paid_by': paidBy,
          'category': category,
          'created_at': date.toIso8601String(),
        })
        .select()
        .single();

    final expenseId = expenseResponse['id'];

    final splitAmount = amount / splitBetweenUserIds.length;

    final splits = splitBetweenUserIds.map((userId) {
      return {
        'expense_id': expenseId,
        'user_id': userId,
        'amount': splitAmount,
      };
    }).toList();

    await _client.from('expense_splits').insert(splits);
  }

  Future<void> deleteExpense(String expenseId) async {
    final client = Supabase.instance.client;

    // حذف split ها
    await client.from('expense_splits').delete().eq('expense_id', expenseId);

    // حذف خود expense
    await client.from('expenses').delete().eq('id', expenseId);
  }

  Future<void> updateExpense({
    required String expenseId,
    required String description,
    required double amount,
    required String category,
    required String paidBy,
    required DateTime date,
    required List<String> splitUserIds,
  }) async {
    final client = Supabase.instance.client;

    await client
        .from('expenses')
        .update({
          'description': description,
          'amount': amount,
          'category': category,
          'paid_by': paidBy,
          'created_at': date.toIso8601String(),
        })
        .eq('id', expenseId);

    // حذف split های قبلی
    await client.from('expense_splits').delete().eq('expense_id', expenseId);

    final share = amount / splitUserIds.length;

    final splits = splitUserIds.map((userId) {
      return {'expense_id': expenseId, 'user_id': userId, 'amount': share};
    }).toList();

    await client.from('expense_splits').insert(splits);
  }

  Future<List<ExpenseSplitModel>> getExpenseSplits(String expenseId) async {
    final response = await _client
        .from('expense_splits')
        .select('''
          id,
          expense_id,
          user_id,
          amount,
          created_at
        ''')
        .eq('expense_id', expenseId);

    return (response as List)
        .map((e) => ExpenseSplitModel.fromJson(e))
        .toList();
  }
}
