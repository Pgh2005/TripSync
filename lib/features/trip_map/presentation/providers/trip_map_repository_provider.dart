import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/features/trip_map/data/repositories/trip_map_repository.dart';

final tripMapRepositoryProvider = Provider<TripMapRepository>((ref) {
  return TripMapRepository(Supabase.instance.client);
});
