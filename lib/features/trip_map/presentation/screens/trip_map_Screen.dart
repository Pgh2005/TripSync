import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';

import '../providers/trip_map_provider.dart';

class TripMapScreen extends ConsumerWidget {
  const TripMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(tripMarkersProvider);

    return Scaffold(
      appBar: AppPrimaryAppBar(title: 'Trip Map'),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(36.2605, 59.6168), // Mashhad
          initialZoom: 13,
          onTap: (tapPosition, point) {
            ref.read(tripMarkersProvider.notifier).addMarker(point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.tripsync',
          ),
          MarkerLayer(
            markers: markers.map((tripMarker) {
              return Marker(
                point: tripMarker.position,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
