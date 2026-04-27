import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/dance_move_model.dart';
import '../../models/favorites_response_model.dart';
import '../../services/dance_service.dart';
import '../welcome/widgets/background_glow.dart';
import 'step_detail_screen.dart';

class StepsScreen extends StatefulWidget {
  final int styleId;
  final String styleName;
  final Color accentColor;
  final IconData styleIcon;

  const StepsScreen({
    super.key,
    required this.styleId,
    required this.styleName,
    required this.accentColor,
    required this.styleIcon,
  });

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final DanceService _danceService = DanceService();
  late Future<List<DanceMoveModel>> _movesFuture;

  final Set<int> _favoriteMoveIds = {};
  bool _favoritesLoaded = false;

  @override
  void initState() {
    super.initState();
    _movesFuture = _danceService.getMovesByStyle(widget.styleId);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _danceService.getFavorites();
      if (!mounted) return;

      setState(() {
        _favoriteMoveIds
          ..clear()
          ..addAll(favorites.moves.map((e) => e.moveId));
        _favoritesLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoritesLoaded = true;
      });
    }
  }

  Future<void> _toggleFavoriteMove(int moveId) async {
    final isFavorite = _favoriteMoveIds.contains(moveId);

    setState(() {
      if (isFavorite) {
        _favoriteMoveIds.remove(moveId);
      } else {
        _favoriteMoveIds.add(moveId);
      }
    });

    try {
      if (isFavorite) {
        await _danceService.removeFavoriteMove(moveId);
      } else {
        await _danceService.addFavoriteMove(moveId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isFavorite) {
          _favoriteMoveIds.add(moveId);
        } else {
          _favoriteMoveIds.remove(moveId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update favorite move.'),
        ),
      );
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
                                  widget.styleName,
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
                              color: widget.accentColor.withValues(alpha: 0.10),
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
                                color:
                                    widget.accentColor.withValues(alpha: 0.14),
                              ),
                              child: Icon(
                                widget.styleIcon,
                                color: widget.accentColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.styleName,
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
                      FutureBuilder<List<DanceMoveModel>>(
                        future: _movesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting ||
                              !_favoritesLoaded) {
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
                                      'Could not load dance moves.',
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
                                          _movesFuture = _danceService
                                              .getMovesByStyle(widget.styleId);
                                        });
                                        _loadFavorites();
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final moves = snapshot.data ?? [];

                          return Column(
                            children: moves.asMap().entries.map((entry) {
                              final index = entry.key;
                              final move = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _StepCard(
                                  number: index + 1,
                                  title: move.name,
                                  accent: widget.accentColor,
                                  isFavorite: _favoriteMoveIds.contains(move.id),
                                  onToggleFavorite: () =>
                                      _toggleFavoriteMove(move.id),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StepDetailsScreen(
                                          styleId: widget.styleId,
                                          moveId: move.id,
                                          styleName: widget.styleName,
                                          stepName: move.name,
                                          accentColor: widget.accentColor,
                                          styleIcon: widget.styleIcon,
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

class _StepCard extends StatelessWidget {
  final int number;
  final String title;
  final Color accent;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _StepCard({
    required this.number,
    required this.title,
    required this.accent,
    required this.isFavorite,
    required this.onToggleFavorite,
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
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite
                      ? AppColors.highlight
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
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