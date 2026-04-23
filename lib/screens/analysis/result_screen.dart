import 'package:flutter/material.dart';
import '../../models/analysis_result_model.dart';
import '../../models/progress_history_item.dart';
import '../../services/progress_service.dart';
import '../../services/result_service.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _screenFuture = _loadData();
  }

  Future<_ResultScreenData> _loadData() async {
    final result = await _resultService.getResultForSession(widget.analysisSessionId);
    final history = await _progressService.getHistory();

    ProgressHistoryItem? currentItem;
    ProgressHistoryItem? previousItem;

    final sorted = [...history]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final item in sorted) {
      if (item.sessionId == widget.analysisSessionId) {
        currentItem = item;
        break;
      }
    }

    if (currentItem != null) {
      final currentIndex = sorted.indexWhere((e) => e.sessionId == currentItem!.sessionId);
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

  List<String> _buildBadges(AnalysisResultModel result) {
    final badges = <String>[];

    if ((result.overallScore ?? 0) >= 9.0) {
      badges.add('Excellent control');
    } else if ((result.overallScore ?? 0) >= 8.0) {
      badges.add('Strong performance');
    }

    if ((result.legsScore ?? 0) > (result.armsScore ?? 0)) {
      badges.add('Strong legs');
    } else if ((result.armsScore ?? 0) > (result.legsScore ?? 0)) {
      badges.add('Strong arms');
    }

    if ((result.overallScore ?? 0) >= 8.5) {
      badges.add('Great timing');
    }

    if (badges.isEmpty) {
      badges.add('Good foundation');
    }

    return badges;
  }

  String _mainStrength(AnalysisResultModel result) {
    final arms = result.armsScore ?? 0;
    final legs = result.legsScore ?? 0;

    if (legs > arms) {
      return 'Your lower-body rhythm and foot placement are currently the strongest part of this performance.';
    }

    if (arms > legs) {
      return 'Your upper-body control and arm accents stand out most in this session.';
    }

    return 'Your movement looks balanced overall, with similar control between upper and lower body.';
  }

  String _mainWeakness(AnalysisResultModel result) {
    final arms = result.armsScore ?? 0;
    final legs = result.legsScore ?? 0;

    if (legs < arms) {
      return 'Focus more on leg timing, foot precision, and consistency in the lower-body transitions.';
    }

    if (arms < legs) {
      return 'Focus more on cleaner arm placement, sharper finishes, and upper-body clarity.';
    }

    return 'Your next improvement step is to refine timing and clean up the final positions of each movement.';
  }

  String _comparisonText(ProgressHistoryItem? current, ProgressHistoryItem? previous) {
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
      return 'This session is $absDiff points lower than your previous one, so it is a good chance to review consistency.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface.withValues(alpha: 0.78),
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
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
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

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface.withValues(alpha: 0.78),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.styleName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.stepName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
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
                        const SizedBox(height: 20),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: badges
                              .map(
                                (badge) => _BadgeChip(label: badge),
                              )
                              .toList(),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Overall score',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                result.overallScore?.toStringAsFixed(1) ?? '--',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _ScoreCard(
                                title: 'Arms',
                                value: result.armsScore,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _ScoreCard(
                                title: 'Legs',
                                value: result.legsScore,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _HighlightCard(
                          title: 'Main strength',
                          content: _mainStrength(result),
                          icon: Icons.emoji_events_rounded,
                        ),

                        const SizedBox(height: 16),

                        _HighlightCard(
                          title: 'Main improvement area',
                          content: _mainWeakness(result),
                          icon: Icons.track_changes_rounded,
                        ),

                        const SizedBox(height: 16),

                        _HighlightCard(
                          title: 'Comparison with previous session',
                          content: _comparisonText(data.currentItem, data.previousItem),
                          icon: Icons.compare_arrows_rounded,
                        ),

                        const SizedBox(height: 16),

                        _TextCard(
                          title: 'AI feedback',
                          content: result.feedbackSummary ??
                              'No summary available yet.',
                        ),

                        const SizedBox(height: 16),

                        _TextCard(
                          title: 'Strengths',
                          content: result.strengthsText ??
                              'No strengths available yet.',
                        ),

                        const SizedBox(height: 16),

                        _TextCard(
                          title: 'Improvements',
                          content: result.improvementsText ??
                              'No improvement suggestions available yet.',
                        ),

                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
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
                              const Text(
                                'Movement heat insight',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Visual demo placeholder',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: const [
                                  _HeatPill(label: 'Arms', level: 0.55),
                                  _HeatPill(label: 'Core', level: 0.72),
                                  _HeatPill(label: 'Legs', level: 0.90),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
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

class _ScoreCard extends StatelessWidget {
  final String title;
  final double? value;

  const _ScoreCard({
    required this.title,
    required this.value,
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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
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
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _HighlightCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            width: 44,
            height: 44,
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

class _TextCard extends StatelessWidget {
  final String title;
  final String content;

  const _TextCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
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
    );
  }
}

class _HeatPill extends StatelessWidget {
  final String label;
  final double level;

  const _HeatPill({
    required this.label,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final width = 70 + (level * 70);

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: width,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.55),
                AppColors.secondary.withValues(alpha: 0.85),
                AppColors.highlight.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
      ],
    );
  }
}