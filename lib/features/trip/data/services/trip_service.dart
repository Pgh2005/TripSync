import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/features/trip/data/models/member_model.dart';
import '../models/trip_model.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createTrip({
    required String title,
    required String destination,
    required DateTime startDate,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است');
    }

    final trip = await _supabase
        .from('trips')
        .insert({
          'title': title,
          'destination': destination,
          'start_date': startDate.toIso8601String().split('T').first,
          'created_by': user.id,
        })
        .select()
        .single();

    await _supabase.from('trip_members').insert({
      'trip_id': trip['id'],
      'user_id': user.id,
    });
  }

  Future<List<TripModel>> getMyTrips() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است');
    }

    final response = await _supabase
        .from('trips')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((trip) => TripModel.fromJson(trip)).toList();
  }

  Future<List<MemberModel>> getTripMembers(String tripId) async {
    final response = await _supabase
        .from('trip_members')
        .select('profiles(*)')
        .eq('trip_id', tripId);

    return (response as List).map((item) {
      return MemberModel.fromJson(item['profiles']);
    }).toList();
  }
}
