class AnalysisResultModel {
  final int id;
  final int analysisSessionId;
  final double? overallScore;
  final double? armsScore;
  final double? legsScore;
  final String? feedbackSummary;
  final String? strengthsText;
  final String? improvementsText;
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
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}