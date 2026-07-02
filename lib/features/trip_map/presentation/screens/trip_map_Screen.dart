import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';

class TripMapScreen extends StatelessWidget {
  const TripMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPrimaryAppBar(title: 'Trip Map'),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(36.310699, 59.599457), // Mashhad
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.tripsync',
          ),
        ],
      ),
    );
  }
}
