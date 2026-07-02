import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

import 'package:tripsync/features/trip_map/data/models/trip_marker_models.dart';

final tripMarkersProvider =
    StateNotifierProvider<TripMarkersNotifier, List<TripMarkerModel>>(
      (ref) => TripMarkersNotifier(),
    );

class TripMarkersNotifier extends StateNotifier<List<TripMarkerModel>> {
  TripMarkersNotifier() : super([]);

  void addMarker({required LatLng position, required String title}) {
    final marker = TripMarkerModel(
      id: _generateId(),
      position: position,
      title: title,
      createdAt: DateTime.now(),
    );

    state = [...state, marker];
  }

  String _generateId() {
    return Random().nextInt(100000).toString();
  }
}
