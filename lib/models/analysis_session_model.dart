class AnalysisSessionModel {
  final int id;
  final int userId;
  final String mode;
  final String sourceType;
  final String status;
  final String inputVideoPath;
  final int? selectedStyleId;
  final int? selectedMoveId;
  final int? predictedStyleId;
  final int? predictedMoveId;
  final DateTime createdAt;
  final DateTime? completedAt;

  AnalysisSessionModel({
    required this.id,
    required this.userId,
    required this.mode,
    required this.sourceType,
    required this.status,
    required this.inputVideoPath,
    required this.selectedStyleId,
    required this.selectedMoveId,
    required this.predictedStyleId,
    required this.predictedMoveId,
    required this.createdAt,
    required this.completedAt,
  });

  factory AnalysisSessionModel.fromJson(Map<String, dynamic> json) {
    return AnalysisSessionModel(
      id: json['id'],
      userId: json['user_id'],
      mode: json['mode'],
      sourceType: json['source_type'],
      status: json['status'],
      inputVideoPath: json['input_video_path'],
      selectedStyleId: json['selected_style_id'],
      selectedMoveId: json['selected_move_id'],
      predictedStyleId: json['predicted_style_id'],
      predictedMoveId: json['predicted_move_id'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}