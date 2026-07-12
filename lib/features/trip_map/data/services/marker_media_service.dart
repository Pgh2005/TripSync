import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:tripsync/core/enums/marker_media_type.dart';
import 'package:tripsync/core/enums/marker_visibility.dart';
import 'package:tripsync/features/trip_map/data/models/marker_media_model.dart';

class MarkerMediaService {
  MarkerMediaService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _bucketName = 'marker-media';

  Future<MarkerMediaModel> uploadMedia({
    required String markerId,
    required String createdBy,
    required File file,
    required MarkerMediaType type,
    required MarkerVisibility visibility,
  }) async {
    final mediaId = const Uuid().v4();
    final extension = _fileExtension(file.path);
    final fileName = extension.isEmpty ? mediaId : '$mediaId.$extension';
    final storagePath = 'markers/$markerId/$fileName';

    await _client.storage
        .from(_bucketName)
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final remoteUrl = _client.storage
        .from(_bucketName)
        .getPublicUrl(storagePath);

    final media = MarkerMediaModel(
      id: mediaId,
      markerId: markerId,
      createdBy: createdBy,
      type: type,
      visibility: visibility,
      storagePath: storagePath,
      remoteUrl: remoteUrl,
      createdAt: DateTime.now(),
    );

    await _client.from('marker_media').insert(media.toJson());
    return media;
  }

  // متد جامع برای گرفتن هر نوع مدیا (عکس یا صوت)
  Future<List<MarkerMediaModel>> getMarkerMedia(
    String markerId,
    MarkerMediaType type,
  ) async {
    try {
      final response = await _client
          .from('marker_media')
          .select()
          .eq('marker_id', markerId)
          .eq('type', type.value); // استفاده از extension شما

      return (response as List<dynamic>)
          .map((e) => MarkerMediaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching marker media ($type): $e');
      return [];
    }
  }

  // برای سازگاری با کدهای قبلی
  Future<List<String?>> getMarkerImages(String markerId) async {
    final mediaList = await getMarkerMedia(markerId, MarkerMediaType.image);
    return mediaList.map((m) => m.remoteUrl).toList();
  }

  Future<void> deleteAllMediaForMarker(String markerId) async {
    try {
      final response = await _client
          .from('marker_media')
          .select('storage_path')
          .eq('marker_id', markerId);

      final List<String> paths = (response as List<dynamic>)
          .map((item) => item['storage_path'] as String?)
          .where((path) => path != null && path.trim().isNotEmpty)
          .cast<String>()
          .toList();

      if (paths.isNotEmpty) {
        await _client.storage.from(_bucketName).remove(paths);
      }

      await _client.from('marker_media').delete().eq('marker_id', markerId);
    } catch (e) {
      debugPrint('Error deleting marker media for marker $markerId: $e');
      rethrow;
    }
  }

  String _fileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return '';
    return path.substring(lastDot + 1).toLowerCase();
  }
}
