class ProgressHistoryItem {
  final int sessionId;
  final String mode;
  final String sourceType;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? styleName;
  final String? moveName;
  final double? overallScore;
  final double? armsScore;
  final double? legsScore;

  ProgressHistoryItem({
    required this.sessionId,
    required this.mode,
    required this.sourceType,
    required this.status,
    required this.createdAt,
    required this.completedAt,
    required this.styleName,
    required this.moveName,
    required this.overallScore,
    required this.armsScore,
    required this.legsScore,
  });

  factory ProgressHistoryItem.fromJson(Map<String, dynamic> json) {
    return ProgressHistoryItem(
      sessionId: json['session_id'],
      mode: json['mode'],
      sourceType: json['source_type'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      styleName: json['style_name'],
      moveName: json['move_name'],
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      armsScore: (json['arms_score'] as num?)?.toDouble(),
      legsScore: (json['legs_score'] as num?)?.toDouble(),
    );
  }
}