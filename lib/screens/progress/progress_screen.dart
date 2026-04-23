import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/progress_history_item.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../analysis/result_screen.dart';
import '../welcome/widgets/background_glow.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService();
  late Future<List<ProgressHistoryItem>> _historyFuture;

  String _selectedFilter = 'All';
  String? _selectedStyle;

  @override
  void initState() {
    super.initState();
    _historyFuture = _progressService.getHistory();
  }

  List<ProgressHistoryItem> _applyFilters(List<ProgressHistoryItem> items) {
    final now = DateTime.now();

    List<ProgressHistoryItem> filtered = List.from(items);

    if (_selectedFilter == 'Today') {
      filtered = filtered.where((item) {
        return item.createdAt.year == now.year &&
            item.createdAt.month == now.month &&
            item.createdAt.day == now.day;
      }).toList();
    }

    if (_selectedFilter == 'Week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      filtered = filtered.where((item) {
        return item.createdAt.isAfter(weekAgo);
      }).toList();
    }

    if (_selectedStyle != null && _selectedStyle != 'All styles') {
      filtered = filtered.where((item) => item.styleName == _selectedStyle).toList();
    }

    return filtered;
  }

  double _averageScore(List<ProgressHistoryItem> items) {
    final scores = items
        .map((e) => e.overallScore)
        .where((e) => e != null)
        .cast<double>()
        .toList();

    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _bestStyle(List<ProgressHistoryItem> items) {
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

  int _activeDays(List<ProgressHistoryItem> items) {
    final uniqueDays = items
        .map((e) => '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}')
        .toSet();
    return uniqueDays.length;
  }

  List<FlSpot> _buildWeeklySpots(List<ProgressHistoryItem> items) {
    final now = DateTime.now();
    final List<double?> dailyAverages = List.filled(7, null);

    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));

      final dayItems = items.where((item) {
        return item.createdAt.year == day.year &&
            item.createdAt.month == day.month &&
            item.createdAt.day == day.day &&
            item.overallScore != null;
      }).toList();

      if (dayItems.isNotEmpty) {
        final avg = dayItems
                .map((e) => e.overallScore!)
                .reduce((a, b) => a + b) /
            dayItems.length;
        dailyAverages[i] = avg;
      }
    }

    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), dailyAverages[index] ?? 0);
    });
  }

  String _weeklyInsight(List<ProgressHistoryItem> items) {
    if (items.isEmpty) {
      return 'No analysis sessions yet. Upload a dance video to start building your progress dashboard.';
    }

    final avg = _averageScore(items);
    final best = _bestStyle(items);
    final sessions = items.length;

    return 'You completed $sessions sessions in the selected range, with an average score of ${avg.toStringAsFixed(1)}. Your strongest style right now appears to be $best.';
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          SafeArea(
            child: FutureBuilder<List<ProgressHistoryItem>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Could not load progress data.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _historyFuture = _progressService.getHistory();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allItems = snapshot.data ?? [];
                final filteredItems = _applyFilters(allItems);

                final styles = <String>{
                  'All styles',
                  ...allItems
                      .map((e) => e.styleName)
                      .where((e) => e != null)
                      .cast<String>(),
                }.toList();

                final avgScore = _averageScore(filteredItems);
                final bestStyle = _bestStyle(filteredItems);
                final activeDays = _activeDays(filteredItems);
                final weeklySpots = _buildWeeklySpots(filteredItems);
                final insight = _weeklyInsight(filteredItems);

                return ScrollConfiguration(
                  behavior: const _NoStretchScrollBehavior(),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Track your sessions, scores, and weekly growth.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: ['All', 'Today', 'Week'].map((filter) {
                              final selected = _selectedFilter == filter;
                              return ChoiceChip(
                                label: Text(filter),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                selectedColor:
                                    AppColors.primary.withValues(alpha: 0.18),
                                backgroundColor:
                                    AppColors.surface.withValues(alpha: 0.85),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStyle ?? 'All styles',
                                dropdownColor: AppColors.surface,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                items: styles.map((style) {
                                  return DropdownMenuItem(
                                    value: style,
                                    child: Text(style),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStyle = value;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Avg Score',
                                  value: avgScore == 0
                                      ? '-'
                                      : avgScore.toStringAsFixed(1),
                                  subtitle: 'Selected range',
                                  icon: Icons.star_rounded,
                                  accent: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Sessions',
                                  value: filteredItems.length.toString(),
                                  subtitle: 'Selected range',
                                  icon: Icons.local_fire_department_rounded,
                                  accent: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Best Style',
                                  value: bestStyle,
                                  subtitle: 'Top performer',
                                  icon: Icons.music_note_rounded,
                                  accent: AppColors.highlight,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _SummaryCard(
                                  title: 'Consistency',
                                  value: '$activeDays',
                                  subtitle: 'Active days',
                                  icon: Icons.insights_rounded,
                                  accent: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weekly score trend',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Your average performance over the last 7 days.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 220,
                                  child: LineChart(
                                    LineChartData(
                                      minY: 0,
                                      maxY: 10,
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: 2,
                                        getDrawingHorizontalLine: (_) => FlLine(
                                          color:
                                              Colors.white.withValues(alpha: 0.06),
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 2,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value.toStringAsFixed(0),
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            getTitlesWidget: (value, meta) {
                                              const labels = [
                                                'M',
                                                'T',
                                                'W',
                                                'T',
                                                'F',
                                                'S',
                                                'S'
                                              ];
                                              final index = value.toInt();
                                              if (index < 0 ||
                                                  index >= labels.length) {
                                                return const SizedBox.shrink();
                                              }
                                              return Text(
                                                labels[index],
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: weeklySpots,
                                          isCurved: true,
                                          barWidth: 4,
                                          isStrokeCapRound: true,
                                          color: AppColors.secondary,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter:
                                                (spot, percent, bar, index) {
                                              return FlDotCirclePainter(
                                                radius: 4.2,
                                                color: AppColors.highlight,
                                                strokeWidth: 2,
                                                strokeColor:
                                                    AppColors.background,
                                              );
                                            },
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                AppColors.secondary
                                                    .withValues(alpha: 0.28),
                                                AppColors.secondary
                                                    .withValues(alpha: 0.02),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weekly insight',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  insight,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Recent activity',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (filteredItems.isEmpty)
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
                              child: const Text(
                                'No sessions found for the selected filters.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else
                            ...filteredItems.map(
                              (session) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _RecentSessionCard(
                                  session: session,
                                  dateLabel: _formatDateLabel(session.createdAt),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  final ProgressHistoryItem session;
  final String dateLabel;

  const _RecentSessionCard({
    required this.session,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scoreText =
        session.overallScore != null ? session.overallScore!.toStringAsFixed(1) : '--';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                analysisSessionId: session.sessionId,
                styleName: session.styleName ?? 'Auto-detect',
                stepName: session.moveName ?? 'Predicted move',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
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
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      scoreText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                session.styleName ?? 'Auto-detect',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.moveName ?? 'Predicted move',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniScore(
                      label: 'Arms',
                      value: session.armsScore,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniScore(
                      label: 'Legs',
                      value: session.legsScore,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final double? value;

  const _MiniScore({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1528),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value != null ? value!.toStringAsFixed(1) : '--',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoStretchScrollBehavior extends ScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}