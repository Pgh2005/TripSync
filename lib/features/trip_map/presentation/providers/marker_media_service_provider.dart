import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/features/trip_map/data/services/marker_media_service.dart';

final markerMediaServiceProvider = Provider<MarkerMediaService>((ref) {
  return MarkerMediaService(client: Supabase.instance.client);
});

final markerImagesProvider = FutureProvider.family<List<String>, String>((
  ref,
  markerId,
) async {
  final mediaService = ref.read(markerMediaServiceProvider);
  return mediaService.getMarkerImages(markerId);
});
