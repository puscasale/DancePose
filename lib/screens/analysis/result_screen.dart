import 'package:flutter/material.dart';
import '../../models/analysis_result_model.dart';
import '../../models/progress_history_item.dart';
import '../../services/progress_service.dart';
import '../../services/result_service.dart';
import '../../theme/app_colors.dart';
import '../navigation/main_navigation_screen.dart';
import '../welcome/widgets/background_glow.dart';

class ResultScreen extends StatefulWidget {
  final int analysisSessionId;
  final String styleName;
  final String stepName;

  const ResultScreen({
    super.key,
    required this.analysisSessionId,
    required this.styleName,
    required this.stepName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ResultService _resultService = ResultService();
  final ProgressService _progressService = ProgressService();

  late Future<_ResultScreenData> _screenFuture;

  static const double _videoFps = 30.0;

  @override
  void initState() {
    super.initState();
    _screenFuture = _loadData();
  }

  Future<_ResultScreenData> _loadData() async {
    final result =
        await _resultService.getResultForSession(widget.analysisSessionId);
    final history = await _progressService.getHistory();

    ProgressHistoryItem? currentItem;
    ProgressHistoryItem? previousItem;

    final sorted = [...history]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final item in sorted) {
      if (item.sessionId == widget.analysisSessionId) {
        currentItem = item;
        break;
      }
    }

    if (currentItem != null) {
      final currentIndex =
          sorted.indexWhere((e) => e.sessionId == currentItem!.sessionId);
      if (currentIndex != -1 && currentIndex + 1 < sorted.length) {
        previousItem = sorted[currentIndex + 1];
      }
    }

    return _ResultScreenData(
      result: result,
      currentItem: currentItem,
      previousItem: previousItem,
    );
  }

  bool _isPlaceholder(String value) {
    final v = value.trim().toLowerCase();
    return v.isEmpty || v.contains('predicting') || v == '--';
  }

  String _displayStyleName(AnalysisResultModel result) {
    if ((result.predictedStyleName ?? '').trim().isNotEmpty) {
      return result.predictedStyleName!;
    }
    if (!_isPlaceholder(widget.styleName)) {
      return widget.styleName;
    }
    return 'Detected style';
  }

  String _displayMoveName(AnalysisResultModel result) {
    if ((result.predictedMoveName ?? '').trim().isNotEmpty) {
      return result.predictedMoveName!;
    }
    if (!_isPlaceholder(widget.stepName)) {
      return widget.stepName;
    }
    return 'Detected move';
  }

  String _scoreLabel(double score) {
    if (score >= 9.0) return 'Excellent';
    if (score >= 8.0) return 'Strong';
    if (score >= 7.0) return 'Good';
    if (score >= 6.0) return 'Developing';
    return 'Needs work';
  }

  List<String> _buildBadges(AnalysisResultModel result) {
    final badges = <String>[];
    final overall = result.overallScore ?? 0;
    final arms = result.armsScore ?? 0;
    final legs = result.legsScore ?? 0;

    badges.add(_scoreLabel(overall));

    if (legs > arms) {
      badges.add('Lower body stronger');
    } else if (arms > legs) {
      badges.add('Upper body stronger');
    }

    if (overall >= 8.5) {
      badges.add('Stable execution');
    }

    return badges;
  }

  String _comparisonText(
    ProgressHistoryItem? current,
    ProgressHistoryItem? previous,
  ) {
    if (current == null || previous == null) {
      return 'No previous session is available yet for comparison.';
    }

    if (current.overallScore == null || previous.overallScore == null) {
      return 'Comparison is not available because one of the sessions has no score yet.';
    }

    final diff = current.overallScore! - previous.overallScore!;
    final absDiff = diff.abs().toStringAsFixed(1);

    if (diff > 0) {
      return 'You improved by $absDiff points compared to your previous session.';
    }

    if (diff < 0) {
      return 'This session is $absDiff points lower than the previous one, so it is a good opportunity to review consistency.';
    }

    return 'Your score is identical to the previous session, which suggests stable performance.';
  }

  String _sessionMeta(ProgressHistoryItem? item) {
    if (item == null) return 'Session details unavailable';

    final date = item.createdAt;
    final dateText =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return '${item.mode} • ${item.sourceType} • $dateText';
  }

  String _formatSecondFromFrame(int? frame) {
    if (frame == null) return '--';
    final seconds = frame / _videoFps;
    return '${seconds.toStringAsFixed(2)} s';
  }

  List<String> _problematicJoints(AnalysisResultModel result) {
    final raw = result.problematicJointsText;
    if (raw == null || raw.trim().isEmpty) return [];

    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map(_prettifyJoint)
        .toList();
  }

  String _prettifyJoint(String joint) {
    return joint
        .split('_')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: FutureBuilder<_ResultScreenData>(
                future: _screenFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.surface.withValues(alpha: 0.82),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Analysis in progress',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'The result is not available yet. Try again in a moment.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _screenFuture = _loadData();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Check Again'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MainNavigationScreen(initialIndex: 0),
                                ),
                                (route) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Back to Home'),
                          ),
                        ),
                      ],
                    );
                  }

                  final data = snapshot.data!;
                  final result = data.result;
                  final badges = _buildBadges(result);
                  final joints = _problematicJoints(result);

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.surface.withValues(alpha: 0.82),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const _SectionEyebrow(text: 'Analysis result'),
                        const SizedBox(height: 10),

                        Text(
                          _displayStyleName(result),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _displayMoveName(result),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sessionMeta(data.currentItem),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: badges
                              .map((badge) => _BadgeChip(label: badge))
                              .toList(),
                        ),

                        const SizedBox(height: 22),

                        _HeroScoreCard(
                          overallScore: result.overallScore,
                          label: _scoreLabel(result.overallScore ?? 0),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _MiniMetricCard(
                                title: 'Arms',
                                value: result.armsScore,
                                icon: Icons.accessibility_new_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniMetricCard(
                                title: 'Legs',
                                value: result.legsScore,
                                icon: Icons.directions_run_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        const _SectionHeader(
                          title: 'Key moments',
                          subtitle:
                              'The strongest and weakest detected moments in your performance.',
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _MomentInfoCard(
                                title: 'Best moment',
                                timeText: _formatSecondFromFrame(
                                  result.bestNoviceFrame,
                                ),
                                icon: Icons.emoji_events_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MomentInfoCard(
                                title: 'Needs improvement',
                                timeText: _formatSecondFromFrame(
                                  result.worstNoviceFrame,
                                ),
                                icon: Icons.track_changes_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _HeatmapCard(
                                title: 'Best heatmap',
                                subtitle: _formatSecondFromFrame(
                                  result.bestNoviceFrame,
                                ),
                                imageUrl: result.bestHeatmapUrl,
                                icon: Icons.emoji_events_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HeatmapCard(
                                title: 'Worst heatmap',
                                subtitle: _formatSecondFromFrame(
                                  result.worstNoviceFrame,
                                ),
                                imageUrl: result.worstHeatmapUrl,
                                icon: Icons.warning_amber_rounded,
                              ),
                            ),
                          ],
                        ),

                        if (joints.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          const _SectionHeader(
                            title: 'Most problematic joints',
                            subtitle:
                                'These body points showed the largest deviation in the weaker moment.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: joints
                                .map((joint) => _JointChip(label: joint))
                                .toList(),
                          ),
                        ],

                        const SizedBox(height: 26),

                        const _SectionHeader(
                          title: 'AI coach feedback',
                          subtitle:
                              'Short, practical feedback generated from the movement analysis.',
                        ),
                        const SizedBox(height: 14),

                        _AiTextCard(
                          title: 'Summary',
                          content: result.feedbackSummary ??
                              'No summary available yet.',
                          icon: Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(height: 12),
                        _AiTextCard(
                          title: 'Strengths',
                          content: result.strengthsText ??
                              'No strengths available yet.',
                          icon: Icons.trending_up_rounded,
                        ),
                        const SizedBox(height: 12),
                        _AiTextCard(
                          title: 'Improvements',
                          content: result.improvementsText ??
                              'No improvement suggestions available yet.',
                          icon: Icons.build_circle_rounded,
                        ),

                        const SizedBox(height: 26),

                        _InsightCard(
                          title: 'Comparison with previous session',
                          content:
                              _comparisonText(data.currentItem, data.previousItem),
                          icon: Icons.compare_arrows_rounded,
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MainNavigationScreen(initialIndex: 0),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Back to Home'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultScreenData {
  final AnalysisResultModel result;
  final ProgressHistoryItem? currentItem;
  final ProgressHistoryItem? previousItem;

  _ResultScreenData({
    required this.result,
    required this.currentItem,
    required this.previousItem,
  });
}

class _SectionEyebrow extends StatelessWidget {
  final String text;

  const _SectionEyebrow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;

  const _BadgeChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JointChip extends StatelessWidget {
  final String label;

  const _JointChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.highlight.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.highlight.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroScoreCard extends StatelessWidget {
  final double? overallScore;
  final String label;

  const _HeroScoreCard({
    required this.overallScore,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final score = overallScore ?? 0.0;
    final progress = (score / 10.0).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            AppColors.surface.withValues(alpha: 0.98),
            AppColors.primary.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 108,
                  height: 108,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.secondary),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '/10',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall score',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String title;
  final double? value;
  final IconData icon;

  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.secondary.withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              color: AppColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.toStringAsFixed(1) ?? '--',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentInfoCard extends StatelessWidget {
  final String title;
  final String timeText;
  final IconData icon;

  const _MomentInfoCard({
    required this.title,
    required this.timeText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.highlight, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;

  const _HeatmapCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.highlight, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _HeatmapPlaceholder();
                      },
                    )
                  : const _HeatmapPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapPlaceholder extends StatelessWidget {
  const _HeatmapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.04),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: Colors.white.withValues(alpha: 0.55),
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            'Heatmap unavailable',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.highlight.withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              color: AppColors.highlight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiTextCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _AiTextCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}