import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/dance_style_model.dart';
import '../../services/dance_service.dart';
import '../welcome/widgets/background_glow.dart';
import 'steps_screen.dart';

class LearningStylesScreen extends StatefulWidget {
  const LearningStylesScreen({super.key});

  @override
  State<LearningStylesScreen> createState() => _LearningStylesScreenState();
}

class _LearningStylesScreenState extends State<LearningStylesScreen> {
  final DanceService _danceService = DanceService();
  late Future<List<DanceStyleModel>> _stylesFuture;

  @override
  void initState() {
    super.initState();
    _stylesFuture = _danceService.getStyles();
  }

  Color _getAccentColor(String styleName) {
    switch (styleName) {
      case 'House':
        return AppColors.secondary;
      case 'Middle Hip-Hop':
        return AppColors.primary;
      case 'Street Jazz':
        return AppColors.highlight;
      default:
        return AppColors.secondary;
    }
  }

  IconData _getStyleIcon(String styleName) {
    switch (styleName) {
      case 'House':
        return Icons.graphic_eq_rounded;
      case 'Middle Hip-Hop':
        return Icons.bolt_rounded;
      case 'Street Jazz':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          SafeArea(
            child: ScrollConfiguration(
              behavior: const _NoStretchScrollBehavior(),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.surface.withValues(alpha: 0.78),
                              padding: const EdgeInsets.all(12),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Learning',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Choose your style',
                                  style: TextStyle(
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
                      const SizedBox(height: 28),
                      const Text(
                        'Pick a dance style and start learning step by step with guided practice and AI-powered feedback.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 34),
                      FutureBuilder<List<DanceStyleModel>>(
                        future: _stylesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: CircularProgressIndicator(
                                  color: AppColors.secondary,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Could not load dance styles.',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _stylesFuture =
                                              _danceService.getStyles();
                                        });
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final styles = snapshot.data ?? [];

                          return Column(
                            children: styles.map((style) {
                              final accent = _getAccentColor(style.name);
                              final icon = _getStyleIcon(style.name);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 22),
                                child: _StyleCard(
                                  title: style.name,
                                  subtitle: style.description ??
                                      'Start learning this style step by step.',
                                  accent: accent,
                                  icon: icon,
                                  difficulty: '5 moves',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StepsScreen(
                                          styleId: style.id,
                                          styleName: style.name,
                                          accentColor: accent,
                                          styleIcon: icon,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
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

class _StyleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String difficulty;
  final VoidCallback onTap;

  const _StyleCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.18),
                AppColors.surface.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 38,
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MiniTag(
                      label: difficulty,
                      color: accent,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          fontSize: 12,
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