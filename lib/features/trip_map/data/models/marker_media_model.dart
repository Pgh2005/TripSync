import 'package:tripsync/core/enums/marker_media_type.dart';
import 'package:tripsync/core/enums/marker_visibility.dart';

class MarkerMediaModel {
  final String id;
  final String markerId;
  final String createdBy;
  final MarkerMediaType type;
  final MarkerVisibility visibility;
  final String? storagePath;
  final String? remoteUrl;
  final DateTime createdAt;

  const MarkerMediaModel({
    required this.id,
    required this.markerId,
    required this.createdBy,
    required this.type,
    required this.visibility,
    this.storagePath,
    this.remoteUrl,
    required this.createdAt,
  });

  factory MarkerMediaModel.fromJson(Map<String, dynamic> json) {
    return MarkerMediaModel(
      id: json['id'] as String,
      markerId: json['marker_id'] as String,
      createdBy: json['created_by'] as String,
      type: MarkerMediaTypeX.fromValue(json['type'] as String? ?? 'image'),
      visibility: MarkerVisibilityX.fromValue(
        json['visibility'] as String? ?? 'trip_shared',
      ),
      storagePath: json['storage_path'] as String?,
      remoteUrl: json['remote_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marker_id': markerId,
      'created_by': createdBy,
      'type': type.value,
      'visibility': visibility.value,
      'storage_path': storagePath,
      'remote_url': remoteUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
