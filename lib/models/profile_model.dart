class ProfileModel {
  final String id;
  final int roleId;
  final String fullName;
  final String email;
  final String? phone;
  final String? profilePhoto;
  final String? createdAt;
  final String roleName;

  ProfileModel({
    required this.id,
    required this.roleId,
    required this.fullName,
    required this.email,
    this.phone,
    this.profilePhoto,
    this.createdAt,
    required this.roleName,
  });

  factory ProfileModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProfileModel(
      id: json['id'],
      roleId: json['role_id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profilePhoto: json['profile_photo'],
      createdAt: json['created_at'] as String?,
      roleName:
          json['roles']?['name'] ??
          'student',
    );
  }

  // Method untuk konversi ke JSON saat update
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
    };
  }
}