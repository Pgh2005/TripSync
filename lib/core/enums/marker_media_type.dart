enum MarkerMediaType { image, audio }

extension MarkerMediaTypeX on MarkerMediaType {
  String get value {
    switch (this) {
      case MarkerMediaType.image:
        return 'image';
      case MarkerMediaType.audio:
        return 'audio';
    }
  }

  static MarkerMediaType fromValue(String value) {
    switch (value) {
      case 'audio':
        return MarkerMediaType.audio;
      case 'image':
      default:
        return MarkerMediaType.image;
    }
  }
}
