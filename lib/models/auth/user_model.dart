class UserModel {
  final int id;
  final String fullName;
  final String email;
  final int? age;
  final String? danceLevel;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.age,
    this.danceLevel,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      age: json['age'],
      danceLevel: json['dance_level'],
    );
  }
}