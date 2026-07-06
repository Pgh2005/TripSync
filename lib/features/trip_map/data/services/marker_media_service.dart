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

  String _fileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) {
      return '';
    }
    return path.substring(lastDot + 1).toLowerCase();
  }

  // در کلاس MarkerMediaService
  Future<List<String>> getMarkerImages(String markerId) async {
    try {
      final response = await _client
          .from('marker_media')
          .select('remote_url')
          .eq('marker_id', markerId)
          .eq('type', 'image'); // فقط فیلتر روی عکس‌ها

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => item['remote_url'] as String).toList();
    } catch (e) {
      debugPrint('Error fetching marker images: $e');
      return [];
    }
  }
}
