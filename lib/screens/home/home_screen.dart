import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/auth/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/home_stats_service.dart';
import '../../theme/app_colors.dart';
import '../analysis/result_screen.dart';
import '../analysis/start_dance_screen.dart';
import '../learning/learning_styles_screen.dart';
import '../welcome/widgets/background_glow.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VideoPlayerController _videoController;
  final AuthService _authService = AuthService();
  final HomeStatsService _homeStatsService = HomeStatsService();

  bool _isLoadingUser = true;
  UserModel? _currentUser;

  late Future<HomeDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/featured_move.mp4',
    )
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
        }
      });

    _dashboardFuture = _homeStatsService.getDashboardData();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _homeStatsService.getDashboardData();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  String _getDisplayName() {
    if (_currentUser == null) return 'Dancer';

    final fullName = _currentUser!.fullName.trim();
    if (fullName.isEmpty) return 'Dancer';

    final parts = fullName.split(' ');
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName();

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: _refreshDashboard,
              child: ScrollConfiguration(
                behavior: const _NoStretchScrollBehavior(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: FutureBuilder<HomeDashboardData>(
                      future: _dashboardFuture,
                      builder: (context, snapshot) {
                        final dashboard = snapshot.data;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surface,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.16),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Transform.scale(
                                      scale: 1.35,
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/DancePose_logov3.png',
                                          fit: BoxFit.contain,
                                          width: 46,
                                          height: 46,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.music_note_rounded,
                                              color: AppColors.primary,
                                              size: 22,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Welcome back',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _isLoadingUser
                                          ? Container(
                                              width: 90,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            )
                                          : Text(
                                              displayName,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: AppColors.secondary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${dashboard?.totalSessions ?? 0} sessions',
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.30),
                                    AppColors.secondary.withValues(alpha: 0.18),
                                    AppColors.surface.withValues(alpha: 0.95),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.14),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Dashboard',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Ready to master your next move?',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    dashboard == null
                                        ? 'Your real-time stats will appear here as soon as your dashboard finishes loading.'
                                        : 'You have ${dashboard.totalSessions} total sessions, and your current best style is ${dashboard.bestStyle}.',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      _InfoChip(
                                        icon: Icons.star_rounded,
                                        label: dashboard?.latestScore != null
                                            ? 'Last score ${dashboard!.latestScore!.toStringAsFixed(1)}'
                                            : 'No score yet',
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 10),
                                      _InfoChip(
                                        icon: Icons.insights_rounded,
                                        label: dashboard?.bestStyle != null
                                            ? 'Best: ${dashboard!.bestStyle}'
                                            : 'No data yet',
                                        color: AppColors.highlight,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: _SmallDashboardCard(
                                    title: 'Latest score',
                                    value: dashboard?.latestScore != null
                                        ? dashboard!.latestScore!.toStringAsFixed(1)
                                        : '--',
                                    icon: Icons.emoji_events_rounded,
                                    accent: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _SmallDashboardCard(
                                    title: 'Best style',
                                    value: dashboard?.bestStyle ?? '-',
                                    icon: Icons.graphic_eq_rounded,
                                    accent: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _SmallDashboardCard(
                                    title: 'Sessions',
                                    value: '${dashboard?.totalSessions ?? 0}',
                                    icon: Icons.local_fire_department_rounded,
                                    accent: AppColors.highlight,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _SmallDashboardCard(
                                    title: 'Status',
                                    value: snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? 'Loading'
                                        : 'Synced',
                                    icon: Icons.cloud_done_rounded,
                                    accent: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            if (dashboard?.latestSession != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Continue from your latest result',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${dashboard!.latestSession!.styleName ?? 'Auto-detect'} • ${dashboard.latestSession!.moveName ?? 'Predicted move'}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ResultScreen(
                                                analysisSessionId:
                                                    dashboard.latestSession!.sessionId,
                                                styleName: dashboard.latestSession!
                                                        .styleName ??
                                                    'Auto-detect',
                                                stepName: dashboard.latestSession!
                                                        .moveName ??
                                                    'Predicted move',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.play_arrow_rounded),
                                        label: const Text('Open latest result'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 26),

                            const Text(
                              'Start here',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 14),

                            _FeatureCard(
                              title: 'Learning',
                              subtitle:
                                  'Choose a style, pick a move, and practice step by step.',
                              icon: Icons.school_rounded,
                              accent: AppColors.secondary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LearningStylesScreen(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            _FeatureCard(
                              title: 'Start Dance',
                              subtitle:
                                  'Upload or record a video and get an instant performance report.',
                              icon: Icons.play_circle_fill_rounded,
                              accent: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StartDanceScreen(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.08),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: _videoController.value.isInitialized
                                          ? VideoPlayer(_videoController)
                                          : Container(
                                              color: const Color(0xFF0E1528),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Featured move',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'House Two-Step',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'A smooth groove-based step to build rhythm, balance, and flow.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Row(
                                    children: [
                                      _MiniTag(
                                        label: 'House',
                                        color: AppColors.secondary,
                                      ),
                                      SizedBox(width: 8),
                                      _MiniTag(
                                        label: 'Beginner',
                                        color: AppColors.highlight,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _SmallDashboardCard({
    required this.title,
    required this.value,
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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