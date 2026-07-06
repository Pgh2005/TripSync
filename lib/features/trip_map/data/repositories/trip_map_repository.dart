import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/enums/marker_filter.dart';
import 'package:tripsync/core/enums/marker_visibility.dart';
import 'package:tripsync/features/trip_map/data/models/trip_marker_models.dart';

class TripMapRepository {
  final SupabaseClient _supabase;

  TripMapRepository(this._supabase);

  Future<List<TripMarkerModel>> getMarkersByTrip({
    required String tripId,
    required String currentUserId,
    required MarkerFilter filter,
  }) async {
    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('trip_markers')
        .select()
        .eq('trip_id', tripId);

    switch (filter) {
      case MarkerFilter.all:
        query = query.or(
          'created_by.eq.$currentUserId,visibility.eq.${MarkerVisibility.tripShared.value}',
        );
        break;
      case MarkerFilter.mine:
        query = query.eq('created_by', currentUserId);
        break;
      case MarkerFilter.shared:
        query = query
            .eq('visibility', MarkerVisibility.tripShared.value)
            .neq('created_by', currentUserId);
        break;
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => TripMarkerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripMarkerModel> createMarker({
    required String tripId,
    required String currentUserId,
    required double latitude,
    required double longitude,
    required MarkerVisibility visibility,
    String? title,
  }) async {
    final response = await _supabase
        .from('trip_markers')
        .insert({
          'trip_id': tripId,
          'created_by': currentUserId,
          'latitude': latitude,
          'longitude': longitude,
          'visibility': visibility.value,
          'title': title,
        })
        .select()
        .single();

    return TripMarkerModel.fromJson(response);
  }

  Future<void> deleteMarker(String markerId) async {
    await _supabase.from('trip_markers').delete().eq('id', markerId);
  }
}
