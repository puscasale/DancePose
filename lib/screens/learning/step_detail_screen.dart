import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../services/analysis_service.dart';
import '../welcome/widgets/background_glow.dart';
import '../analysis/video_review_screen.dart';

class StepDetailsScreen extends StatefulWidget {
  final int styleId;
  final int moveId;
  final String styleName;
  final String stepName;
  final Color accentColor;
  final IconData styleIcon;

  const StepDetailsScreen({
    super.key,
    required this.styleId,
    required this.moveId,
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
  final ImagePicker _picker = ImagePicker();
  final AnalysisService _analysisService = AnalysisService();

  bool _isBusy = false;

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

      if (!mounted) return;
      setState(() {});
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
          return 'Side Kick is a foundational house step built around groove, rebound, and clean side extension. The movement usually relies on a light bounce through the knees while one leg opens outward with clear rhythmic timing. Good execution depends on balance, relaxed posture, and staying connected to the beat rather than kicking too hard.';
        case 'Sworl':
          return 'Sworl is a rotational house movement that emphasizes circular flow through the feet, hips, and torso. It should feel smooth and musical, not rigid. The key is to let the turn travel naturally through the body while keeping the groove alive underneath the rotation.';
        case 'Farmer':
          return 'Farmer is a grounded house step based on weight transfer and steady rhythmic placement of the feet. It helps build control, stability, and a stronger sense of timing. The movement works best when the dancer stays relaxed in the upper body and precise in the lower body.';
        case 'Shuffle':
          return 'Shuffle in house dance focuses on quick foot switches, sliding actions, and continuous groove. It should look fluid rather than stiff or mechanical. The quality of the step often comes from staying low, maintaining even rhythm, and controlling the transitions between foot placements.';
        case 'Heel Step':
          return 'Heel Step highlights heel placement as a rhythmic accent inside house footwork. It trains precision, timing, and body control while keeping the groove soft and natural. A strong execution depends on clean contact with the floor and smooth coordination between feet and torso.';
      }
    }

    if (styleName == 'Middle Hip-Hop') {
      switch (stepName) {
        case 'Rager Rabbit':
          return 'Rager Rabbit is an energetic hip-hop groove with quick rebounds and playful accents. The movement should stay sharp but still feel relaxed and musical. It usually works best when the dancer controls the bounce carefully and keeps the rhythm clear through the whole body.';
        case 'Club':
          return 'Club is a compact groove-based step often built around pulse, confidence, and repeatable rhythm. The chest, knees, and body center help drive the movement. It should feel grounded and socially musical, not overcomplicated.';
        case 'Brooklyn Bounce':
          return 'Brooklyn Bounce is centered on a strong bounce quality generated through the knees, torso, and side-to-side groove. The movement should look grounded, loose, and rhythmically confident. The bounce needs to lead the body naturally instead of being added artificially on top.';
        case 'Running Man':
          return 'Running Man is a classic street dance step built from alternating slide-and-step mechanics that create the illusion of running in place. Strong execution depends on rhythm consistency, clean foot placement, and keeping the movement light rather than heavy.';
        case 'Popcorn':
          return 'Popcorn combines bounce with quick explosive accents that give the movement a reactive quality. It should feel controlled and rhythmic rather than random. The key is to balance small hits with a stable groove underneath.';
      }
    }

    if (styleName == 'Street Jazz') {
      switch (stepName) {
        case 'Positions des pieds':
          return 'Positions des pieds focuses on correct foot placement and body alignment, serving as a technical base for more advanced jazz movement. The goal is clarity, symmetry, and awareness of how the lower body supports posture and transitions.';
        case 'Plié':
          return 'Plié is a fundamental bending action through the knees while maintaining posture, alignment, and control. In jazz-based movement it helps develop softness, strength, and preparation for transitions, turns, and jumps. The knees should bend with control and the body should remain lifted.';
        case 'Jump':
          return 'Jump in street jazz trains elevation, control, and safe landings. The movement is not only about height, but also about posture, timing, pointed feet, and absorbing impact correctly through the legs. A clean jump starts and finishes with control.';
        case 'Passé Balance':
          return 'Passé Balance develops stability and placement by lifting one leg into passé while maintaining posture on the supporting side. It is useful for training balance, alignment, and body control before turns or more complex combinations.';
        case 'Paddbre':
          return 'Paddbre acts as a connecting transition step that supports direction change and stylistic flow inside jazz movement. It should look elegant, intentional, and coordinated, with a calm upper body and clear lower-body placement.';
      }
    }

    return 'Focus on rhythm, posture, and movement clarity. Repeat the step slowly first, then gradually increase the speed while keeping control.';
  }

  Future<void> _openReviewScreen({
    required XFile videoFile,
    required String sourceType,
    required String sourceLabel,
  }) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoReviewScreen(
          videoPath: videoFile.path,
          sourceLabel: sourceLabel,
          title: 'Review your practice video',
          subtitle:
              'Check if the selected move is clearly visible before starting analysis.',
          styleName: widget.styleName,
          stepName: widget.stepName,
          onRetry: () {
            Navigator.pop(context);
          },
          onConfirm: () {
            return _analysisService.uploadAnalysisVideo(
              mode: 'learning',
              sourceType: sourceType,
              filePath: videoFile.path,
              selectedStyleId: widget.styleId,
              selectedMoveId: widget.moveId,
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickVideoFromGallery() async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
    });

    try {
      final XFile? pickedVideo = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (!mounted) return;

      if (pickedVideo != null) {
        await _openReviewScreen(
          videoFile: pickedVideo,
          sourceType: 'gallery',
          sourceLabel: 'Gallery upload',
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the gallery.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _recordVideoWithCamera() async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
    });

    try {
      final XFile? recordedVideo = await _picker.pickVideo(
        source: ImageSource.camera,
      );

      if (!mounted) return;

      if (recordedVideo != null) {
        await _openReviewScreen(
          videoFile: recordedVideo,
          sourceType: 'camera',
          sourceLabel: 'Camera recording',
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the camera.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _isBusy
                                ? null
                                : () {
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(height: 8),
                                  Text(
                                    _getStepDescription(
                                      widget.styleName,
                                      widget.stepName,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Practice tips',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 10),
                            _InfoLine('Keep your full body visible.'),
                            _InfoLine('Try to perform only the selected move.'),
                            _InfoLine('Avoid long pauses before or after the movement.'),
                            _InfoLine('After recording, review the clip before analysis.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isBusy ? null : _pickVideoFromGallery,
                          icon: _isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : const Icon(Icons.upload_rounded),
                          label: Text(_isBusy ? 'Uploading...' : 'Upload Video'),
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
                          onPressed: _isBusy ? null : _recordVideoWithCamera,
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

class _InfoLine extends StatelessWidget {
  final String text;

  const _InfoLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.secondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
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