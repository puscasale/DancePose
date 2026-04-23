import '../models/progress_history_item.dart';
import 'progress_service.dart';

class HomeDashboardData {
  final int totalSessions;
  final double? latestScore;
  final String bestStyle;
  final ProgressHistoryItem? latestSession;

  HomeDashboardData({
    required this.totalSessions,
    required this.latestScore,
    required this.bestStyle,
    required this.latestSession,
  });
}

class HomeStatsService {
  final ProgressService _progressService = ProgressService();

  Future<HomeDashboardData> getDashboardData() async {
    final history = await _progressService.getHistory();

    final sorted = [...history]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final latestSession = sorted.isNotEmpty ? sorted.first : null;
    final latestScore = latestSession?.overallScore;

    final bestStyle = _computeBestStyle(sorted);

    return HomeDashboardData(
      totalSessions: sorted.length,
      latestScore: latestScore,
      bestStyle: bestStyle,
      latestSession: latestSession,
    );
  }

  String _computeBestStyle(List<ProgressHistoryItem> items) {
    final Map<String, List<double>> styleScores = {};

    for (final item in items) {
      if (item.styleName != null && item.overallScore != null) {
        styleScores.putIfAbsent(item.styleName!, () => []);
        styleScores[item.styleName!]!.add(item.overallScore!);
      }
    }

    if (styleScores.isEmpty) return '-';

    String best = '-';
    double bestAvg = -1;

    styleScores.forEach((style, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        best = style;
      }
    });

    return best;
  }
}