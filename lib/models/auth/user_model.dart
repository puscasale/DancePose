class UserModel {
  final int id;
  final String fullName;
  final String email;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
    );
  }
}