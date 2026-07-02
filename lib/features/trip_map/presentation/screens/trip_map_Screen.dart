import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/add_marker_sheet.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/marker_info_sheet.dart';

import '../providers/trip_map_provider.dart';

class TripMapScreen extends ConsumerWidget {
  const TripMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(tripMarkersProvider);

    return Scaffold(
      appBar: const AppPrimaryAppBar(title: 'نقشه سفر'),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(36.2605, 59.6168), // مشهد
          initialZoom: 13,
          onLongPress: (tapPosition, point) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddMarkerSheet(point: point),
            );
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
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => MarkerInfoSheet(title: tripMarker.title),
                    );
                  },
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.markercolor,
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
