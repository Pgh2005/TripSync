import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/utils/invite_code_generator.dart';
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
          'invite_code': InviteCodeGenerator.generate(),
        })
        .select()
        .single();

    await _supabase.from('trip_members').insert({
      'trip_id': trip['id'],
      'user_id': user.id,
    });
  }

  Future<List<TripModel>> getUserTrips() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است');
    }

    final response = await _supabase
        .from('trip_members')
        .select('trips(*)')
        .eq('user_id', user.id);

    return (response as List)
        .where((item) => item['trips'] != null)
        .map((item) => TripModel.fromJson(item['trips']))
        .toList();
  }

  Future<List<MemberModel>> getTripMembers(String tripId) async {
    final response = await _supabase
        .from('trip_members')
        .select('profiles(*)')
        .eq('trip_id', tripId);

    return (response as List)
        .where((item) => item['profiles'] != null)
        .map((item) => MemberModel.fromJson(item['profiles']))
        .toList();
  }

  Future<TripModel?> getTripByInviteCode(String code) async {
    final response = await _supabase
        .from('trips')
        .select()
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return TripModel.fromJson(response);
  }

  Future<void> joinTrip(String tripId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است');
    }

    final existing = await _supabase
        .from('trip_members')
        .select()
        .eq('trip_id', tripId)
        .eq('user_id', user.id);

    if (existing.isNotEmpty) {
      throw Exception('شما قبلاً عضو این سفر شده‌اید');
    }

    await _supabase.from('trip_members').insert({
      'trip_id': tripId,
      'user_id': user.id,
    });
  }

  Future<void> deleteTrip(String tripId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است');
    }

    // حذف اعضای سفر
    await _supabase.from('trip_members').delete().eq('trip_id', tripId);

    // حذف خود سفر
    await _supabase.from('trips').delete().eq('id', tripId);
  }
}
