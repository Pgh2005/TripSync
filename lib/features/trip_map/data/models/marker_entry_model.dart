import 'package:tripsync/core/enums/marker_visibility.dart';

class MarkerEntryModel {
  final String id;
  final String markerId;
  final String createdBy;
  final String title;
  final String? summary;
  final String? description;
  final MarkerVisibility visibility;
  final DateTime createdAt;

  const MarkerEntryModel({
    required this.id,
    required this.markerId,
    required this.createdBy,
    required this.title,
    this.summary,
    this.description,
    required this.visibility,
    required this.createdAt,
  });

  factory MarkerEntryModel.fromJson(Map<String, dynamic> json) {
    return MarkerEntryModel(
      id: json['id'] as String,
      markerId: json['marker_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      visibility: MarkerVisibilityX.fromValue(
        json['visibility'] as String? ?? 'trip_shared',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marker_id': markerId,
      'created_by': createdBy,
      'title': title,
      'summary': summary,
      'description': description,
      'visibility': visibility.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
