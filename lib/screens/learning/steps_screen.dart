import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../welcome/widgets/background_glow.dart';
import 'step_detail_screen.dart';

class StepsScreen extends StatelessWidget {
  final String styleName;
  final Color accentColor;
  final IconData styleIcon;

  const StepsScreen({
    super.key,
    required this.styleName,
    required this.accentColor,
    required this.styleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final steps = _getStepsForStyle(styleName);

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
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  styleName,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Choose a move',
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

                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.10),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: accentColor.withValues(alpha: 0.14),
                              ),
                              child: Icon(
                                styleIcon,
                                color: accentColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    styleName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Select one move and start learning it step by step.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      ...steps.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final step = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _StepCard(
                              number: index + 1,
                              title: step,
                              accent: accentColor,
                              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => StepDetailsScreen(
        styleName: styleName,
        stepName: step,
        accentColor: accentColor,
        styleIcon: styleIcon,
      ),
    ),
  );
},
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

List<String> _getStepsForStyle(String styleName) {
  switch (styleName) {
    case 'House':
      return const [
        'Side Kick',
        'Sworl',
        'Farmer',
        'Shuffle',
        'Heel Step',
      ];
    case 'Middle Hip-Hop':
      return const [
        'Rager Rabbit',
        'Club',
        'Brooklyn Bounce',
        'Running Man',
        'Popcorn',
      ];
    case 'Street Jazz':
      return const [
        'Positions des pieds',
        'Plié',
        'Jump',
        'Passé Balance',
        'Paddbre',
      ];
    default:
      return const [
        'Move 1',
        'Move 2',
        'Move 3',
        'Move 4',
        'Move 5',
      ];
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  const _StepCard({
    required this.number,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
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
