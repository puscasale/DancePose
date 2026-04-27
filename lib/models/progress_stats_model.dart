class StyleAverageItemModel {
  final String styleName;
  final double averageScore;

  StyleAverageItemModel({
    required this.styleName,
    required this.averageScore,
  });

  factory StyleAverageItemModel.fromJson(Map<String, dynamic> json) {
    return StyleAverageItemModel(
      styleName: json['style_name'],
      averageScore: (json['average_score'] as num).toDouble(),
    );
  }
}

class ProgressStatsModel {
  final double? bestScoreEver;
  final int totalSessions;
  final String? mostPracticedMove;
  final DateTime? lastActivity;
  final List<StyleAverageItemModel> averageByStyle;

  ProgressStatsModel({
    required this.bestScoreEver,
    required this.totalSessions,
    required this.mostPracticedMove,
    required this.lastActivity,
    required this.averageByStyle,
  });

  factory ProgressStatsModel.fromJson(Map<String, dynamic> json) {
    return ProgressStatsModel(
      bestScoreEver: json['best_score_ever'] != null
          ? (json['best_score_ever'] as num).toDouble()
          : null,
      totalSessions: json['total_sessions'],
      mostPracticedMove: json['most_practiced_move'],
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
      averageByStyle: (json['average_by_style'] as List<dynamic>)
          .map((e) => StyleAverageItemModel.fromJson(e))
          .toList(),
    );
  }
}