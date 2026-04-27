import 'package:flutter/material.dart';

import '../../models/auth/user_model.dart';
import '../../models/favorites_response_model.dart';
import '../../services/auth_service.dart';
import '../../services/dance_service.dart';
import '../../theme/app_colors.dart';
import '../learning/step_detail_screen.dart';
import '../learning/steps_screen.dart';
import '../welcome/welcome_screen.dart';
import '../welcome/widgets/background_glow.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DanceService _danceService = DanceService();

  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isDeleting = false;

  UserModel? _user;
  FavoritesResponseModel? _favorites;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      final favorites = await _danceService.getFavorites();

      if (!mounted) return;

      setState(() {
        _user = user;
        _favorites = favorites;
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

      await _loadUser();

      if (!mounted) return;

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

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete account?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This action is permanent. Your account and analysis history will be removed.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlight,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _handleDeleteAccount();
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _authService.deleteAccount();

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
          content: Text('Could not delete account. Please try again.'),
        ),
      );

      setState(() {
        _isDeleting = false;
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

  String _formatDanceLevel(String? level) {
    if (level == null || level.isEmpty) return 'Not set';

    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return level;
    }
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

  void _openFavoriteStyle(FavoriteStyleItem style) {
    final accent = _getAccentColor(style.styleName);
    final icon = _getStyleIcon(style.styleName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StepsScreen(
          styleId: style.styleId,
          styleName: style.styleName,
          accentColor: accent,
          styleIcon: icon,
        ),
      ),
    );
  }

  void _openFavoriteMove(FavoriteMoveItem move) {
    if (move.styleId == null || move.styleName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This move is missing style information.'),
        ),
      );
      return;
    }

    final accent = _getAccentColor(move.styleName!);
    final icon = _getStyleIcon(move.styleName!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StepDetailsScreen(
          styleId: move.styleId!,
          moveId: move.moveId,
          styleName: move.styleName!,
          stepName: move.moveName,
          accentColor: accent,
          styleIcon: icon,
        ),
      ),
    );
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
                                            builder: (_) =>
                                                const ChangePasswordScreen(),
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
                                      onPressed: _isDeleting
                                          ? null
                                          : _showDeleteAccountDialog,
                                      icon: _isDeleting
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: AppColors.highlight,
                                              ),
                                            )
                                          : const Icon(Icons.delete_outline_rounded),
                                      label: Text(
                                        _isDeleting
                                            ? 'Deleting account...'
                                            : 'Delete Account',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.highlight,
                                        side: BorderSide(
                                          color: AppColors.highlight
                                              .withValues(alpha: 0.35),
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
                            const SizedBox(height: 12),
                            _InfoTile(
                              icon: Icons.cake_outlined,
                              title: 'Age',
                              value: _user?.age != null ? '${_user!.age}' : 'Not set',
                            ),
                            const SizedBox(height: 12),
                            _InfoTile(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Dance level',
                              value: _formatDanceLevel(_user?.danceLevel),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle('Favorites'),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
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
                                  const Text(
                                    'Favorite styles',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_favorites == null || _favorites!.styles.isEmpty)
                                    const Text(
                                      'No favorite styles yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _favorites!.styles
                                          .map(
                                            (style) => _FavoriteTag(
                                              label: style.styleName,
                                              color: AppColors.secondary,
                                              onTap: () =>
                                                  _openFavoriteStyle(style),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Favorite moves',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_favorites == null || _favorites!.moves.isEmpty)
                                    const Text(
                                      'No favorite moves yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _favorites!.moves
                                          .map(
                                            (move) => _FavoriteTag(
                                              label: move.moveName,
                                              color: AppColors.highlight,
                                              onTap: () =>
                                                  _openFavoriteMove(move),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                ],
                              ),
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
        const Center(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    height: 1.4,
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

class _FavoriteTag extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FavoriteTag({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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