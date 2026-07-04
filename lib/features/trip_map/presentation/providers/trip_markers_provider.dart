import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/features/trip_map/data/models/trip_marker_models.dart';
import 'package:tripsync/features/trip_map/presentation/providers/marker_filter_provider.dart';
import 'package:tripsync/features/trip_map/presentation/providers/trip_map_repository_provider.dart';

final tripMarkersProvider =
    FutureProvider.family<List<TripMarkerModel>, String>((ref, tripId) async {
      final repository = ref.read(tripMapRepositoryProvider);
      final filter = ref.watch(markerFilterProvider);
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      return repository.getMarkersByTrip(
        tripId: tripId,
        currentUserId: currentUser.id,
        filter: filter,
      );
    });
