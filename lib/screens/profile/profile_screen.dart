import 'package:flutter/material.dart';
import '../../models/auth/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../welcome/welcome_screen.dart';
import '../welcome/widgets/background_glow.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isLoggingOut = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    if (_user == null) return;

    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _user!),
      ),
    );

    if (updatedUser != null && mounted) {
      setState(() {
        _user = updatedUser;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not log out. Please try again.'),
        ),
      );

      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  String _getInitials() {
    final fullName = _user?.fullName.trim() ?? '';
    if (fullName.isEmpty) return 'DP';

    final parts = fullName.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'DP';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: _isLoading
                      ? const _ProfileLoadingView()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Manage your account and personal settings.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.10),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor:
                                        AppColors.secondary.withValues(alpha: 0.16),
                                    child: Text(
                                      _getInitials(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _user?.fullName ?? 'DancePose User',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _user?.email ?? 'No email available',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _openEditProfile,
                                      icon: const Icon(Icons.edit_rounded),
                                      label: const Text('Edit Profile'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChangePasswordScreen(),
        ),
      );
    },
    icon: const Icon(Icons.lock_reset_rounded),
    label: const Text('Change Password'),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  ),
),

const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DeleteAccountScreen(),
        ),
      );
    },
    icon: const Icon(Icons.delete_outline_rounded),
    label: const Text('Delete Account'),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.highlight,
      side: BorderSide(
        color: AppColors.highlight.withValues(alpha: 0.35),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  ),
),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle('Account'),
                            const SizedBox(height: 14),
                            _InfoTile(
                              icon: Icons.person_outline_rounded,
                              title: 'Full name',
                              value: _user?.fullName ?? 'Not available',
                            ),
                            const SizedBox(height: 12),
                            _InfoTile(
                              icon: Icons.mail_outline_rounded,
                              title: 'Email',
                              value: _user?.email ?? 'Not available',
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle('Insights'),
                            const SizedBox(height: 14),
                            Row(
                              children: const [
                                Expanded(
                                  child: _MiniStatCard(
                                    title: 'Sessions',
                                    value: '12',
                                    accent: AppColors.primary,
                                    icon: Icons.local_fire_department_rounded,
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: _MiniStatCard(
                                    title: 'Best style',
                                    value: 'House',
                                    accent: AppColors.secondary,
                                    icon: Icons.graphic_eq_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoggingOut ? null : _handleLogout,
                                icon: _isLoggingOut
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.textPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.logout_rounded),
                                label: Text(
                                  _isLoggingOut ? 'Logging out...' : 'Log Out',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
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

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your account and personal settings.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: CircularProgressIndicator(
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
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