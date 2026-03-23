import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_colors.dart';
import '../welcome/widgets/background_glow.dart';
import 'package:chewie/chewie.dart';

class StepDetailsScreen extends StatefulWidget {
  final String styleName;
  final String stepName;
  final Color accentColor;
  final IconData styleIcon;

  const StepDetailsScreen({
    super.key,
    required this.styleName,
    required this.stepName,
    required this.accentColor,
    required this.styleIcon,
  });

  @override
  State<StepDetailsScreen> createState() => _StepDetailsScreenState();
}

class _StepDetailsScreenState extends State<StepDetailsScreen> {
  late final VideoPlayerController _videoController;
ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
   _videoController = VideoPlayerController.asset(
  _getVideoPath(widget.styleName, widget.stepName),
);

_videoController.initialize().then((_) {
  _chewieController = ChewieController(
    videoPlayerController: _videoController,
    autoPlay: true,
    looping: true,
    allowFullScreen: true,
    allowMuting: true,
    showControls: true,
    materialProgressColors: ChewieProgressColors(
      playedColor: widget.accentColor,
      handleColor: widget.accentColor,
      bufferedColor: AppColors.secondary.withValues(alpha: 0.35),
      backgroundColor: Colors.white.withValues(alpha: 0.14),
    ),
  );

  if (mounted) {
    setState(() {});
  }
});
  }

  @override
  void dispose() {
    _chewieController?.dispose();
_videoController.dispose();
super.dispose();
  }

  String _getVideoPath(String styleName, String stepName) {
  if (styleName == 'House') {
    switch (stepName) {
      case 'Side Kick':
        return 'assets/videos/house/side_kick.mp4';
      case 'Sworl':
        return 'assets/videos/house/swirl.mp4';
      case 'Farmer':
        return 'assets/videos/house/farmer.mp4';
      case 'Shuffle':
        return 'assets/videos/house/shuffle.mp4';
      case 'Heel Step':
        return 'assets/videos/house/heel_step.mp4';
    }
  }

  if (styleName == 'Middle Hip-Hop') {
    switch (stepName) {
      case 'Rager Rabbit':
        return 'assets/videos/middle_hip_hop/rager_rabbit.mp4';
      case 'Club':
        return 'assets/videos/middle_hip_hop/club.mp4';
      case 'Brooklyn Bounce':
        return 'assets/videos/middle_hip_hop/brooklyn_bounce.mp4';
      case 'Running Man':
        return 'assets/videos/middle_hip_hop/running_man.mp4';
      case 'Popcorn':
        return 'assets/videos/middle_hip_hop/popcorn.mp4';
    }
  }

  if (styleName == 'Street Jazz') {
    switch (stepName) {
      case 'Positions des pieds':
        return 'assets/videos/street_jazz/positions_des_pieds.mp4';
      case 'Plié':
        return 'assets/videos/street_jazz/pile.mp4';
      case 'Jump':
        return 'assets/videos/street_jazz/jump.mp4';
      case 'Passé Balance':
        return 'assets/videos/street_jazz/passe_balance.mp4';
      case 'Paddbre':
        return 'assets/videos/street_jazz/paddbre.mp4';
    }
  }

  return 'assets/videos/featured_move.mp4';
}

  String _getStepDescription(String styleName, String stepName) {
  if (styleName == 'House') {
    switch (stepName) {
      case 'Side Kick':
        return 'A basic groove step where the body stays relaxed while one leg extends to the side with a clear rhythmic kick. Focus on bounce, balance, and staying light on the supporting leg.';
      case 'Sworl':
        return 'A turning groove with circular energy through the feet and hips. Keep the upper body loose and let the rotation feel smooth instead of forced.';
      case 'Farmer':
        return 'A grounded house step built around weight shifts and steady foot placement. Think of it as a move that trains control, timing, and a strong connection to the beat.';
      case 'Shuffle':
        return 'A classic house footwork idea based on quick sliding and switching steps. Stay low, keep the rhythm even, and make the movement feel continuous rather than sharp. ';
      case 'Heel Step':
        return 'A house variation that emphasizes heel placement and clean timing. Focus on precision in the feet while keeping the groove soft through the knees and torso.';
    }
  }

  if (styleName == 'Middle Hip-Hop') {
    switch (stepName) {
      case 'Rager Rabbit':
        return 'A playful hip-hop groove built on quick rebounds and energetic accents. The goal is to keep the movement sharp while still looking relaxed and musical.';
      case 'Club':
        return 'A social-style groove with compact steps and a strong pulse in the chest and knees. Keep it confident, grounded, and easy to repeat with the music.';
      case 'Brooklyn Bounce':
        return 'A bounce-based hip-hop move where the groove comes from the knees, torso, and side-to-side rhythm. Focus on staying grounded and letting the bounce lead the whole body.';
      case 'Running Man':
        return 'A well-known old-school street dance step built from alternating slide-and-step actions that imitate running in place. The move works best when the feet stay clean and the rhythm stays consistent. ';
      case 'Popcorn':
        return 'A quick, reactive groove with small explosive accents through the body. Think of it as a move that mixes bounce with sudden controlled hits.';
    }
  }

  if (styleName == 'Street Jazz') {
    switch (stepName) {
      case 'Positions des pieds':
        return 'A foundation exercise focused on clean foot positions and body alignment. Use it to build placement, control, and awareness before more dynamic movement.';
      case 'Plié':
        return 'A fundamental bending action through the knees while maintaining alignment and control. In jazz-based training, plié helps build balance, softness, and power for transitions and jumps. ';
      case 'Jump':
        return 'A basic elevation move where take-off and landing should both stay controlled. Focus on posture, pointed feet, and landing softly through the knees.';
      case 'Passé Balance':
        return 'A balance position where one leg is lifted and placed near the supporting knee. The move develops stability, posture, and control before turns or traveling combinations. ';
      case 'Paddbre':
        return 'A traveling transition step designed to connect movements smoothly. Focus on elegance, clean direction changes, and keeping the upper body composed.';
    }
  }

  return 'Focus on rhythm, body control, and clean timing. Start slowly, then repeat until the movement feels natural.';
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
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
                                Text(
                                  widget.stepName,
                                  style: const TextStyle(
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

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          _MiniTag(
                            label: widget.styleName,
                            color: widget.accentColor,
                          ),
                          const SizedBox(width: 8),
                          const _MiniTag(
                            label: 'Beginner',
                            color: AppColors.highlight,
                          ),
                          const SizedBox(width: 8),
                          const _MiniTag(
                            label: '3 min practice',
                            color: AppColors.secondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: (_chewieController != null &&
        _videoController.value.isInitialized)
    ? Chewie(controller: _chewieController!)
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

                      const SizedBox(height: 22),

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
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color:
                                    widget.accentColor.withValues(alpha: 0.14),
                              ),
                              child: Icon(
                                widget.styleIcon,
                                color: widget.accentColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'About this move',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _getStepDescription(widget.styleName, widget.stepName),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ],
  ),
),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Difficulty',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Beginner',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Practice time',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '3 min',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.upload_rounded),
                          label: const Text('Upload Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accentColor,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.videocam_rounded),
                          label: const Text('Record Now'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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