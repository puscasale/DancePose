import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'widgets/background_glow.dart';
import 'widgets/mini_badge.dart';
import 'widgets/skeleton_motion_graphic.dart';
import '../login/login_screen.dart';
import '../signup/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Transform.scale(
  scale: 1.18,
  child: Image.asset(
    'assets/images/dancepose_logo.png',
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) {
      return const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.primary,
        size: 44,
      );
    },
  ),
),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'DancePose',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Master the Move.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 14),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Learn, track and improve your dance moves with intelligent motion analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: const [
                          MiniBadge(
                            label: 'House',
                            color: AppColors.secondary,
                          ),
                          MiniBadge(
                            label: 'Middle Hip-Hop',
                            color: AppColors.primary,
                          ),
                          MiniBadge(
                            label: 'Street Jazz',
                            color: AppColors.highlight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SkeletonMotionGraphic(),
                      const SizedBox(height: 16),
                      const Text(
                        'AI-powered dance feedback built for movement, rhythm and precision.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SignUpScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
        ),
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
    child: const Text(
      'Get Started',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () { 
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                          const LoginScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    },
  ),
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
                      backgroundColor:
                          AppColors.surface.withValues(alpha: 0.35),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Your movement. Your progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),
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