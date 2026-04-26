class UpdateProfileRequest {
  final String fullName;
  final int? age;
  final String? danceLevel;

  UpdateProfileRequest({
    required this.fullName,
    this.age,
    this.danceLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'age': age,
      'dance_level': danceLevel,
    };
  }
}