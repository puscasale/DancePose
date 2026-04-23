class DanceMoveModel {
  final int id;
  final int styleId;
  final String name;
  final String? description;
  final String? difficulty;
  final String? tutorialVideoPath;

  DanceMoveModel({
    required this.id,
    required this.styleId,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.tutorialVideoPath,
  });

  factory DanceMoveModel.fromJson(Map<String, dynamic> json) {
    return DanceMoveModel(
      id: json['id'],
      styleId: json['style_id'],
      name: json['name'],
      description: json['description'],
      difficulty: json['difficulty'],
      tutorialVideoPath: json['tutorial_video_path'],
    );
  }
}