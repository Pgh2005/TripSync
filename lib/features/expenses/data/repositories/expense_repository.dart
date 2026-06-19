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
}
