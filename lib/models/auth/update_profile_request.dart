class UpdateProfileRequest {
  final String fullName;

  UpdateProfileRequest({
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
    };
  }
}