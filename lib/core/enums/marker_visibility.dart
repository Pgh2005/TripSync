enum MarkerVisibility { ownerOnly, tripShared }

extension MarkerVisibilityX on MarkerVisibility {
  String get value {
    switch (this) {
      case MarkerVisibility.ownerOnly:
        return 'owner_only';
      case MarkerVisibility.tripShared:
        return 'trip_shared';
    }
  }

  static MarkerVisibility fromValue(String value) {
    switch (value) {
      case 'owner_only':
        return MarkerVisibility.ownerOnly;
      case 'trip_shared':
        return MarkerVisibility.tripShared;
      default:
        return MarkerVisibility.tripShared;
    }
  }

  String get label {
    switch (this) {
      case MarkerVisibility.ownerOnly:
        return 'فقط من';
      case MarkerVisibility.tripShared:
        return 'اشتراکی';
    }
  }
}
