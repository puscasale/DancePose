class AnalysisResultModel {
  final int id;
  final int analysisSessionId;
  final double? overallScore;
  final double? armsScore;
  final double? legsScore;

  final String? feedbackSummary;
  final String? strengthsText;
  final String? improvementsText;

  final String? predictedStyleName;
  final String? predictedMoveName;

  final String? problematicJointsText;

  final String? bestHeatmapUrl;
  final String? worstHeatmapUrl;

  final int? bestNoviceFrame;
  final int? bestExpertFrame;
  final int? worstNoviceFrame;
  final int? worstExpertFrame;

  final DateTime createdAt;

  AnalysisResultModel({
    required this.id,
    required this.analysisSessionId,
    required this.overallScore,
    required this.armsScore,
    required this.legsScore,
    required this.feedbackSummary,
    required this.strengthsText,
    required this.improvementsText,
    required this.predictedStyleName,
    required this.predictedMoveName,
    required this.problematicJointsText,
    required this.bestHeatmapUrl,
    required this.worstHeatmapUrl,
    required this.bestNoviceFrame,
    required this.bestExpertFrame,
    required this.worstNoviceFrame,
    required this.worstExpertFrame,
    required this.createdAt,
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return AnalysisResultModel(
      id: json['id'],
      analysisSessionId: json['analysis_session_id'],
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      armsScore: (json['arms_score'] as num?)?.toDouble(),
      legsScore: (json['legs_score'] as num?)?.toDouble(),
      feedbackSummary: json['feedback_summary'],
      strengthsText: json['strengths_text'],
      improvementsText: json['improvements_text'],
      predictedStyleName: json['predicted_style_name'],
      predictedMoveName: json['predicted_move_name'],
      problematicJointsText: json['problematic_joints_text'],
      bestHeatmapUrl: json['best_heatmap_url'],
      worstHeatmapUrl: json['worst_heatmap_url'],
      bestNoviceFrame: json['best_novice_frame'],
      bestExpertFrame: json['best_expert_frame'],
      worstNoviceFrame: json['worst_novice_frame'],
      worstExpertFrame: json['worst_expert_frame'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}