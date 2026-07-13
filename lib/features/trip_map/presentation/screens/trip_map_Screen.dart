import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripsync/core/utils/snackbar_helper.dart';
import 'package:tripsync/core/widgets/appbar_primary.dart';
import 'package:tripsync/features/trip_map/data/models/trip_marker_models.dart';
import 'package:tripsync/features/trip_map/presentation/providers/trip_markers_provider.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/add_marker_sheet.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/map_control_buttons.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/marker_info_sheet.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/trip_map_banner.dart';
import 'package:tripsync/features/trip_map/presentation/widgets/user_location_marker.dart';

class TripMapScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripMapScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends ConsumerState<TripMapScreen> {
  final MapController _mapController = MapController();

  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  bool _isFindingLocation = false;

  // وضعیت‌های بنر بالای صفحه
  String? _mapBannerText;
  Color _mapBannerColor = Colors.black54;
  IconData? _mapBannerIcon;

  static const LatLng _defaultCenter = LatLng(35.6892, 51.3890); // Tehran
  static const double _defaultZoom = 13.0;
  static const double _focusedZoom = 15.5;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _showMapBanner(
    String text, {
    Color color = Colors.black54,
    IconData? icon,
  }) {
    if (!mounted) return;
    setState(() {
      _mapBannerText = text;
      _mapBannerColor = color;
      _mapBannerIcon = icon;
    });
  }

  void _hideMapBanner() {
    if (!mounted) return;
    setState(() {
      _mapBannerText = null;
      _mapBannerColor = Colors.black54;
      _mapBannerIcon = null;
    });
  }

  Future<void> _initLocationTracking() async {
    _showMapBanner('در حال پیدا کردن موقعیت شما...', icon: Icons.my_location);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMapBanner(
          'سرویس موقعیت‌یاب خاموش است',
          color: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMapBanner(
          'دسترسی موقعیت مکانی رد شد',
          color: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMapBanner(
          'دسترسی موقعیت مکانی برای همیشه بسته شده است',
          color: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      final currentPosition = LatLng(current.latitude, current.longitude);

      setState(() {
        _currentPosition = currentPosition;
      });

      // پرش اولیه به موقعیت کاربر بعد از دریافت لوکیشن
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(currentPosition, _focusedZoom);
      });

      _showMapBanner(
        'موقعیت شما پیدا شد',
        color: Colors.green,
        icon: Icons.check_circle,
      );

      Future.delayed(const Duration(seconds: 2), () {
        _hideMapBanner();
      });

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((position) {
            if (!mounted) return;

            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
            });
          });
    } catch (e) {
      _showMapBanner(
        'خطا در پیدا کردن موقعیت',
        color: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _goToMyLocation() async {
    if (_isFindingLocation) return;

    setState(() {
      _isFindingLocation = true;
    });

    _showMapBanner('در حال پیدا کردن موقعیت شما...', icon: Icons.my_location);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMapBanner(
          'سرویس موقعیت‌یاب خاموش است',
          color: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMapBanner(
          'دسترسی موقعیت مکانی رد شد',
          color: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMapBanner(
          'دسترسی موقعیت مکانی برای همیشه بسته شده است',
          color: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newPosition;
      });

      _mapController.move(newPosition, _focusedZoom);

      _showMapBanner(
        'موقعیت شما پیدا شد',
        color: Colors.green,
        icon: Icons.check_circle,
      );

      Future.delayed(const Duration(seconds: 2), () {
        _hideMapBanner();
      });
    } catch (e) {
      _showMapBanner(
        'خطا در پیدا کردن موقعیت',
        color: Colors.redAccent,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFindingLocation = false;
        });
      }
    }
  }

  Future<void> _openAddMarkerSheet(LatLng point) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return AddMarkerSheet(tripId: widget.tripId, point: point);
      },
    );

    ref.invalidate(tripMarkersProvider(widget.tripId));
  }

  Future<void> _openMarkerInfoSheet(TripMarkerModel marker) async {
    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: MarkerInfoSheet(marker: marker, tripId: widget.tripId),
        );
      },
    );

    if (!mounted) return;
    ref.invalidate(tripMarkersProvider(widget.tripId));
  }

  List<Marker> _buildMapMarkers(List<TripMarkerModel> tripMarkers) {
    final markers = <Marker>[];

    for (final marker in tripMarkers) {
      markers.add(
        Marker(
          point: LatLng(marker.latitude, marker.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _openMarkerInfoSheet(marker),
            child: const Icon(Icons.location_on, size: 40, color: Colors.red),
          ),
        ),
      );
    }

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 50,
          height: 50,
          child: const UserLocationMarker(),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(tripMarkersProvider(widget.tripId));

    return Scaffold(
      appBar: AppPrimaryAppBar(title: 'نقشه سفر'),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? _defaultCenter,
              initialZoom: _defaultZoom,
              onLongPress: (_, point) => _openAddMarkerSheet(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.tripsync',
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              markersAsync.when(
                data: (tripMarkers) {
                  final allMarkers = _buildMapMarkers(tripMarkers);
                  return MarkerLayer(markers: allMarkers);
                },
                loading: () {
                  final fallbackMarkers = _currentPosition != null
                      ? [
                          Marker(
                            point: _currentPosition!,
                            width: 50,
                            height: 50,
                            child: const UserLocationMarker(),
                          ),
                        ]
                      : <Marker>[];

                  return MarkerLayer(markers: fallbackMarkers);
                },
                error: (_, _) {
                  final fallbackMarkers = _currentPosition != null
                      ? [
                          Marker(
                            point: _currentPosition!,
                            width: 50,
                            height: 50,
                            child: const UserLocationMarker(),
                          ),
                        ]
                      : <Marker>[];

                  return MarkerLayer(markers: fallbackMarkers);
                },
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: MapControlButtons(
              onMyLocationTap: _goToMyLocation,
              onHelpTap: () {
                SnackbarHelper.showInfo(
                  context,
                  'برای افزودن مارکر، روی نقشه چند لحظه نگه دارید \n برای مشاهده اطلاعات مارکر، روی آن ضربه بزنید.',
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: markersAsync.when(
              data: (tripMarkers) {
                final bannerText =
                    _mapBannerText ??
                    (tripMarkers.isEmpty
                        ? 'هنوز هیچ مارکری برای این سفر ثبت نشده. با نگه داشتن روی نقشه، اولین مارکر را اضافه کن.'
                        : null);

                if (bannerText == null) {
                  return const SizedBox.shrink();
                }

                return TripMapBanner(
                  text: bannerText,
                  backgroundColor: _mapBannerText == null
                      ? Colors.black54
                      : _mapBannerColor,
                  icon: _mapBannerText == null
                      ? Icons.touch_app
                      : _mapBannerIcon,
                );
              },
              loading: () {
                return TripMapBanner(
                  text: _mapBannerText ?? 'در حال بارگذاری مارکرها...',
                  backgroundColor: _mapBannerColor,
                  icon: _mapBannerIcon ?? Icons.hourglass_empty,
                );
              },
              error: (error, _) {
                return TripMapBanner(
                  text: _mapBannerText ?? 'خطا در دریافت مارکرها',
                  backgroundColor: _mapBannerText == null
                      ? Colors.redAccent
                      : _mapBannerColor,
                  icon: _mapBannerText == null
                      ? Icons.error_outline
                      : _mapBannerIcon,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
