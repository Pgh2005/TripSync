import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsync/core/enums/marker_filter.dart';

final markerFilterProvider = StateProvider<MarkerFilter>((ref) {
  return MarkerFilter.all;
});
