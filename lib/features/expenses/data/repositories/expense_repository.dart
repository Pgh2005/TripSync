import 'package:supabase_flutter/supabase_flutter.dart';
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
}
