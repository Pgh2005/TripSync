import 'package:latlong2/latlong.dart';

class TripMarkerModel {
  final String id;
  final LatLng position;
  final String title;
  final DateTime createdAt;

  TripMarkerModel({
    required this.id,
    required this.position,
    required this.title,
    required this.createdAt,
  });
}
