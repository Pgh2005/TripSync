import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripsync/core/theme/app_colors.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/add_marker_sheet.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/marker_info_sheet.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/user_location_marker.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/map_control_buttons.dart';
import '../providers/trip_map_provider.dart';

class TripMapScreen extends ConsumerStatefulWidget {
  const TripMapScreen({super.key});

  @override
  ConsumerState<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends ConsumerState<TripMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationTracking();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      SnackbarHelper.showError(context, 'لطفا GPS خود را روشن کنید');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        SnackbarHelper.showError(context, 'اجازه دسترسی به لوکیشن داده نشد');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      SnackbarHelper.showError(
        context,
        'دسترسی به لوکیشن برای همیشه غیرفعال است. از تنظیمات گوشی فعال کنید.',
      );
      return;
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen(
          (Position position) {
            if (!mounted) return;
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
            });
          },
          onError: (error) {
            if (!mounted) return;
            SnackbarHelper.showError(
              context,
              'خطا در ردیابی زنده موقعیت مکانی',
            );
          },
        );

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition!, 16.0);
    } catch (e) {
      // خطا به نرمی هندل شود
    }
  }

  void _animateToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 16.0);
    } else {
      SnackbarHelper.showInfo(context, 'در حال دریافت سیگنال GPS...');
      _initLocationTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(tripMarkersProvider);

    return Scaffold(
      appBar: const AppPrimaryAppBar(title: 'نقشه سفر'),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(36.2605, 59.6168),
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
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.example.tripsync',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              MarkerLayer(
                markers: [
                  // استفاده از نشانگر موقعیت تفکیک‌شده و تمیز
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 30,
                      height: 30,
                      child: const UserLocationMarker(),
                    ),

                  // رسم مارکرهای ثبت شده
                  ...markers.map((tripMarker) {
                    return Marker(
                      point: tripMarker.position,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => MarkerInfoSheet(
                              title: tripMarker.title,
                              onDelete: () {
                                ref
                                    .read(tripMarkersProvider.notifier)
                                    .removeMarker(tripMarker.id);
                                context.pop(true);
                                SnackbarHelper.showSuccess(
                                  context,
                                  'با موفقیت حذف شد',
                                );
                              },
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.markercolor,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          // استفاده از ویجت دکمه‌های کنترل نقشه تفکیک‌شده
          MapControlButtons(onMyLocationPressed: _animateToCurrentLocation),
        ],
      ),
    );
  }
}
