class TripMemberModel {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const TripMemberModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory TripMemberModel.fromJson(Map<String, dynamic> json) {
    return TripMemberModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}
