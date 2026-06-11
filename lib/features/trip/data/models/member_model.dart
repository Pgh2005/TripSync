class MemberModel {
  final String id;
  final String fullName;
  final String? avatarUrl;

  MemberModel({required this.id, required this.fullName, this.avatarUrl});

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}
