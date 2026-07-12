import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsync/core/enums/marker_media_type.dart';
import 'package:tripsync/features/trip_map/data/models/marker_media_model.dart';
import 'package:tripsync/features/trip_map/data/services/marker_media_service.dart';

final markerMediaServiceProvider = Provider<MarkerMediaService>((ref) {
  return MarkerMediaService(client: Supabase.instance.client);
});

// اصلاح شده برای رفع خطای Type mismatch
final markerImagesProvider = FutureProvider.family<List<String>, String>((
  ref,
  markerId,
) async {
  final mediaService = ref.watch(markerMediaServiceProvider);
  final images = await mediaService.getMarkerImages(markerId);
  // فیلتر کردن نال‌های احتمالی و تبدیل به لیست غیر-نال
  return images.whereType<String>().toList();
});

// پرووایدر جدید برای صوت‌ها
final markerAudiosProvider =
    FutureProvider.family<List<MarkerMediaModel>, String>((
      ref,
      markerId,
    ) async {
      final mediaService = ref.watch(markerMediaServiceProvider);
      return mediaService.getMarkerMedia(markerId, MarkerMediaType.audio);
    });

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:tripsync/core/enums/marker_media_type.dart';
// import 'package:tripsync/features/trip_map/data/services/marker_media_service.dart';

// final markerMediaServiceProvider = Provider<MarkerMediaService>((ref) {
//   return MarkerMediaService(client: Supabase.instance.client);
// });

// final markerImagesProvider = FutureProvider.family<List<String>, String>((
//   ref,
//   markerId,
// ) async {
//   final mediaService = ref.read(markerMediaServiceProvider);
//   return mediaService.getMarkerImages(markerId);
// });
