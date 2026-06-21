import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/features/trip/data/models/trip_member_model.dart';

final tripMembersProvider =
    FutureProvider.family<List<TripMemberModel>, String>((ref, tripId) async {
      final response = await Supabase.instance.client
          .from('trip_members')
          .select('user_id, profiles(full_name, avatar_url)')
          .eq('trip_id', tripId);

      return response.map<TripMemberModel>((row) {
        final profile = row['profiles'] as Map<String, dynamic>?;

        return TripMemberModel(
          id: row['user_id'] as String,
          fullName: profile?['full_name'] as String? ?? 'کاربر ناشناس',
          avatarUrl: profile?['avatar_url'] as String?,
        );
      }).toList();
    });
