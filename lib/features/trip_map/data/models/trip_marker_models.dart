import 'package:tripsync/core/enums/marker_visibility.dart';

class TripMarkerModel {
  final String id;
  final String tripId;
  final String createdBy;
  final double latitude;
  final double longitude;
  final MarkerVisibility visibility;
  final DateTime createdAt;
  final String? title; // این فیلد جدید را اضافه کن

  TripMarkerModel({
    required this.id,
    required this.tripId,
    required this.createdBy,
    required this.latitude,
    required this.longitude,
    required this.visibility,
    required this.createdAt,
    this.title, // در کانستراکتور اضافه کن
  });

  // آپدیت fromJson
  factory TripMarkerModel.fromJson(Map<String, dynamic> json) {
    return TripMarkerModel(
      id: json['id'],
      tripId: json['trip_id'],
      createdBy: json['created_by'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      visibility: MarkerVisibilityX.fromValue(
        json['visibility'] as String? ?? 'trip_shared',
      ),
      createdAt: DateTime.parse(json['created_at']),
      title: json['title'], // خواندن از دیتابیس
    );
  }

  // آپدیت toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'created_by': createdBy,
      'latitude': latitude,
      'longitude': longitude,
      'visibility': visibility.value,
      'created_at': createdAt.toIso8601String(),
      'title': title, 
    };
  }

  // آپدیت copyWith (خیلی مهم!)
  TripMarkerModel copyWith({
    String? id,
    String? tripId,
    String? createdBy,
    double? latitude,
    double? longitude,
    MarkerVisibility? visibility,
    DateTime? createdAt,
    String? title,
  }) {
    return TripMarkerModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      createdBy: createdBy ?? this.createdBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
    );
  }
}
