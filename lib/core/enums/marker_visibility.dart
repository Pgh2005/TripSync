enum MarkerVisibility { ownerOnly, tripShared }

extension MarkerVisibilityX on MarkerVisibility {
  // این متد برای تبدیل رشته دیتابیس به Enum
  static MarkerVisibility fromValue(String value) {
    switch (value) {
      case 'owner_only':
      case 'ownerOnly':
        return MarkerVisibility.ownerOnly;
      case 'trip_shared':
      case 'tripShared':
      default:
        return MarkerVisibility.tripShared;
    }
  }

  // این متد برای ذخیره در دیتابیس (تبدیل Enum به رشته)
  String get value {
    switch (this) {
      case MarkerVisibility.ownerOnly:
        return 'owner_only';
      case MarkerVisibility.tripShared:
        return 'trip_shared';
    }
  }
}
