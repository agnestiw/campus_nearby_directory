class ProfileModel {
  final String id;
  final int roleId;
  final String fullName;
  final String email;
  final String? phone;
  final String? profilePhoto;
  final String roleName;

  ProfileModel({
    required this.id,
    required this.roleId,
    required this.fullName,
    required this.email,
    this.phone,
    this.profilePhoto,
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
      roleName:
          json['roles']?['name'] ??
          'student',
    );
  }
}