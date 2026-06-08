class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int memberCount;
  final TripStatus status;
  final String? coverImage;

  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.memberCount,
    required this.status,
    this.coverImage,
  });
}

enum TripStatus { planning, confirmed, completed }

extension TripStatusX on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.planning:
        return 'در حال برنامه‌ریزی';
      case TripStatus.confirmed:
        return 'تأیید شده';
      case TripStatus.completed:
        return 'تمام شده';
    }
  }
}
