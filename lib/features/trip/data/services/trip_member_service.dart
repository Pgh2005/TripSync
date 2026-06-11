import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trip_member_model.dart';

class TripMemberService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TripMemberModel>> getTripMembers(String tripId) async {
    final response = await _supabase
        .from('trip_members')
        .select('''
          profiles (
            id,
            full_name,
            avatar_url
          )
        ''')
        .eq('trip_id', tripId);

    return (response as List)
        .map((item) => TripMemberModel.fromJson(item['profiles']))
        .toList();
  }
}
