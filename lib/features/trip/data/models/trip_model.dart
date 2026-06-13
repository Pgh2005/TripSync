class TripModel {
  final String id;
  final String title;
  final String destination;
  final DateTime? startDate;
  final String createdBy;
  final DateTime createdAt;
  final String inviteCode;

  TripModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.createdBy,
    required this.createdAt,
    required this.inviteCode,
    this.startDate,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      title: json['title'] as String,
      destination: json['destination'] as String,

      createdBy: json['created_by'] as String,

      createdAt: DateTime.parse(json['created_at'] as String),

      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      inviteCode: json['invite_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
    };
  }

  TripModel copyWith({
    String? id,
    String? title,
    String? destination,
    String? createdBy,
    DateTime? createdAt,
    DateTime? startDate,
    String? inviteCode,
  }) {
    return TripModel(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}
