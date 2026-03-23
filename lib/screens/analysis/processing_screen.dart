import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../welcome/widgets/background_glow.dart';

class ProcessingScreen extends StatefulWidget {
  final String styleName;
  final String stepName;
  final String sourceLabel;
  final String? filePath;

  const ProcessingScreen({
    super.key,
    required this.styleName,
    required this.stepName,
    required this.sourceLabel,
    this.filePath,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _scanController;
  Timer? _statusTimer;
  int _statusIndex = 0;

  final List<String> _statuses = const [
    'Extracting frames...',
    'Detecting body joints...',
    'Building pose skeleton...',
    'Preparing AI analysis...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (!mounted) return;
      setState(() {
        _statusIndex = (_statusIndex + 1) % _statuses.length;
      });
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  const SizedBox(height: 22),
                  const Text(
                    'Analyzing your movement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.styleName} • ${widget.stepName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Source: ${widget.sourceLabel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 310,
                    height: 310,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _pulseController,
                        _scanController,
                      ]),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _ProcessingSkeletonPainter(
                            pulse: _pulseController.value,
                            progress: _scanController.value,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _statuses[_statusIndex],
                      key: ValueKey(_statuses[_statusIndex]),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We are extracting pose keypoints and preparing the motion sequence for AI evaluation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_scanController.value * 0.85) + 0.1,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF1A2137),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(10 + (_scanController.value * 85)).toInt()}%',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingSkeletonPainter extends CustomPainter {
  final double pulse;
  final double progress;

  _ProcessingSkeletonPainter({
    required this.pulse,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pulseWave = 0.92 + math.sin(pulse * math.pi * 2) * 0.05;
    final reveal = Curves.easeInOut.transform(progress);

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    final secondaryGlowPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);

    canvas.drawCircle(center, 84 * pulseWave, glowPaint);
    canvas.drawCircle(center, 54 * pulseWave, secondaryGlowPaint);

    final points = <Offset>[
      Offset(center.dx - 22, center.dy - 95), // 0
      Offset(center.dx - 8, center.dy - 108), // 1
      Offset(center.dx + 8, center.dy - 95), // 2
      Offset(center.dx + 22, center.dy - 108), // 3
      Offset(center.dx + 38, center.dy - 95), // 4
      Offset(center.dx - 56, center.dy - 46), // 5
      Offset(center.dx + 56, center.dy - 46), // 6
      Offset(center.dx - 70, center.dy + 2), // 7
      Offset(center.dx + 70, center.dy + 2), // 8
      Offset(center.dx - 64, center.dy + 58), // 9
      Offset(center.dx + 64, center.dy + 58), // 10
      Offset(center.dx - 26, center.dy + 24), // 11
      Offset(center.dx + 26, center.dy + 24), // 12
      Offset(center.dx - 18, center.dy + 92), // 13
      Offset(center.dx + 18, center.dy + 92), // 14
      Offset(center.dx - 24, center.dy + 158), // 15
      Offset(center.dx + 24, center.dy + 158), // 16
    ];

    final connections = <List<int>>[
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
      [5, 6],
      [5, 7],
      [7, 9],
      [6, 8],
      [8, 10],
      [5, 11],
      [6, 12],
      [11, 12],
      [11, 13],
      [13, 15],
      [12, 14],
      [14, 16],
    ];

    final linePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final dimLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final connection in connections) {
      canvas.drawLine(
        points[connection[0]],
        points[connection[1]],
        dimLinePaint,
      );
    }

    final visibleConnections = (connections.length * reveal).floor();
    for (int i = 0; i < visibleConnections; i++) {
      canvas.drawLine(
        points[connections[i][0]],
        points[connections[i][1]],
        linePaint,
      );
    }

    final visiblePoints = (points.length * reveal).floor();

    final pointGlowPaint = Paint()
      ..color = AppColors.highlight.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final pointPaint = Paint()
      ..color = AppColors.highlight;

    for (int i = 0; i < visiblePoints; i++) {
      canvas.drawCircle(points[i], 9 * pulseWave, pointGlowPaint);
      canvas.drawCircle(points[i], 4.8, pointPaint);
    }

    final scanY = size.height * progress;
    final scanRect = Rect.fromLTWH(0, scanY - 18, size.width, 36);
    final scanGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        AppColors.secondary.withValues(alpha: 0.14),
        Colors.transparent,
      ],
    );
    final scanPaint = Paint()..shader = scanGradient.createShader(scanRect);
    canvas.drawRect(scanRect, scanPaint);

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 118, ringPaint);
    canvas.drawCircle(center, 138, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _ProcessingSkeletonPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.progress != progress;
  }
}