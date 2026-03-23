import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../welcome/widgets/background_glow.dart';
import 'steps_screen.dart';

class LearningStylesScreen extends StatelessWidget {
  const LearningStylesScreen({super.key});

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

                      _StyleCard(
                        title: 'House',
                        subtitle:
                            'Groove-based movement focused on rhythm, bounce, and flow.',
                        accent: AppColors.secondary,
                        icon: Icons.graphic_eq_rounded,
                        difficulty: '5 moves',
                        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StepsScreen(
        styleName: 'House',
        accentColor: AppColors.secondary,
        styleIcon: Icons.graphic_eq_rounded,
      ),
    ),
  );
},
                      ),

                      const SizedBox(height: 22),

                      _StyleCard(
                        title: 'Middle Hip-Hop',
                        subtitle:
                            'Sharp, grounded, and musical moves with strong control.',
                        accent: AppColors.primary,
                        icon: Icons.bolt_rounded,
                        difficulty: '5 moves',
                        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StepsScreen(
        styleName: 'Middle Hip-Hop',
        accentColor: AppColors.primary,
        styleIcon: Icons.bolt_rounded,
      ),
    ),
  );
},
                      ),

                      const SizedBox(height: 22),

                      _StyleCard(
                        title: 'Street Jazz',
                        subtitle:
                            'Expressive, stylish movement with attitude and clean lines.',
                        accent: AppColors.highlight,
                        icon: Icons.auto_awesome_rounded,
                        difficulty: '5 moves',
                        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StepsScreen(
        styleName: 'Street Jazz',
        accentColor: AppColors.highlight,
        styleIcon: Icons.auto_awesome_rounded,
      ),
    ),
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