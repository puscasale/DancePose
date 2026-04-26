import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/analysis_service.dart';
import '../../theme/app_colors.dart';
import '../welcome/widgets/background_glow.dart';
import 'video_review_screen.dart';

class StartDanceScreen extends StatefulWidget {
  const StartDanceScreen({super.key});

  @override
  State<StartDanceScreen> createState() => _StartDanceScreenState();
}

class _StartDanceScreenState extends State<StartDanceScreen> {
  final ImagePicker _picker = ImagePicker();
  final AnalysisService _analysisService = AnalysisService();
  bool _isBusy = false;

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
          title: 'Review your video',
          subtitle:
              'Check the framing before analysis. If needed, record again or choose another clip.',
          styleName: 'Auto-detect mode',
          stepName: 'Predicting move...',
          onRetry: () {
            Navigator.pop(context);
          },
          onConfirm: () {
            return _analysisService.uploadAnalysisVideo(
              mode: 'auto',
              sourceType: sourceType,
              filePath: videoFile.path,
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
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

  Future<void> _recordWithCamera() async {
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Dance',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Analyze your movement',
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
                          color: AppColors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(26),
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
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: AppColors.primary.withValues(alpha: 0.14),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto-detect mode',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Upload or record a dance video and let the AI predict the style and move automatically.',
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
                      const SizedBox(height: 24),
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
                              'Recording tips',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 10),
                            _InfoLine('Keep your full body visible.'),
                            _InfoLine('Use stable camera placement and good lighting.'),
                            _InfoLine('Record only one move if possible.'),
                            _InfoLine('After recording, you will be able to review the video before analysis.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ActionCard(
                        title: 'Upload from Gallery',
                        subtitle:
                            'Choose an existing dance video from your phone.',
                        icon: Icons.upload_rounded,
                        accent: AppColors.secondary,
                        onTap: _isBusy ? null : _pickFromGallery,
                      ),
                      const SizedBox(height: 18),
                      _ActionCard(
                        title: 'Record with Camera',
                        subtitle:
                            'Record your dance and review the clip before starting analysis.',
                        icon: Icons.videocam_rounded,
                        accent: AppColors.primary,
                        onTap: _isBusy ? null : _recordWithCamera,
                      ),
                      if (_isBusy) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(26),
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
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: accent.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: 30,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
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