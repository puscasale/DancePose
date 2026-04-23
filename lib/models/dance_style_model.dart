class DanceStyleModel {
  final int id;
  final String name;
  final String? description;

  DanceStyleModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory DanceStyleModel.fromJson(Map<String, dynamic> json) {
    return DanceStyleModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}