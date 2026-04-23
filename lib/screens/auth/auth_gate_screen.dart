import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../navigation/main_navigation_screen.dart';
import '../welcome/welcome_screen.dart';
import '../welcome/widgets/background_glow.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        _goToWelcome();
        return;
      }

      await _authService.getCurrentUser();
      _goToHome();
    } catch (_) {
      await _authService.logout();
      _goToWelcome();
    }
  }

  void _goToWelcome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
    );
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.20),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/DancePose_logov3.png',
                        fit: BoxFit.cover,
                        width: 102,
                        height: 102,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.primary,
                            size: 40,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'DancePose',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Checking your session...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppColors.secondary,
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