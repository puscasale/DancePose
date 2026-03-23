import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SkeletonMotionGraphic extends StatefulWidget {
  const SkeletonMotionGraphic({super.key});

  @override
  State<SkeletonMotionGraphic> createState() => _SkeletonMotionGraphicState();
}

class _SkeletonMotionGraphicState extends State<SkeletonMotionGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 190),
            painter: SkeletonPainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class SkeletonPainter extends CustomPainter {
  final double progress;

  SkeletonPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final t = progress * math.pi * 2;

    final swayX = math.sin(t) * 10;
    final bounceY = math.sin(t * 2).abs() * 3;
    final armSwing = math.sin(t) * 10;
    final legSwing = math.cos(t) * 8;
    final shoulderTilt = math.sin(t) * 3;
    final hipTilt = math.cos(t) * 2;

    // HEAD KEYPOINTS
    final p0 = Offset(cx - 18 + swayX, 20 + bounceY);
    final p1 = Offset(cx - 6 + swayX, 12 + bounceY);
    final p2 = Offset(cx + 6 + swayX, 20 + bounceY);
    final p3 = Offset(cx + 18 + swayX, 12 + bounceY);
    final p4 = Offset(cx + 30 + swayX, 20 + bounceY);

    // shoulders
    final p5 = Offset(cx - 46 + swayX, 58 - shoulderTilt + bounceY);
    final p6 = Offset(cx + 46 + swayX, 58 + shoulderTilt + bounceY);

    // elbows
    final p7 = Offset(cx - 58 + swayX - armSwing * 0.4, 96 + bounceY);
    final p8 = Offset(cx + 58 + swayX + armSwing * 0.4, 96 + bounceY);

    // wrists
    final p9 = Offset(cx - 52 + swayX - armSwing * 0.7, 136 + bounceY);
    final p10 = Offset(cx + 52 + swayX + armSwing * 0.7, 136 + bounceY);

    // hips
    final p11 = Offset(cx - 22 + swayX, 118 - hipTilt + bounceY);
    final p12 = Offset(cx + 22 + swayX, 118 + hipTilt + bounceY);

    // knees
    final p13 = Offset(cx - 14 + swayX - legSwing * 0.25, 176 + bounceY);
    final p14 = Offset(cx + 14 + swayX + legSwing * 0.25, 176 + bounceY);

    // ankles
    final p15 = Offset(cx - 18 + swayX - legSwing, 246 + bounceY);
    final p16 = Offset(cx + 18 + swayX + legSwing, 246 + bounceY);

    Offset fit(Offset p) => Offset(
          p.dx,
          p.dy * 0.58,
        );

    final points = [
      fit(p0),
      fit(p1),
      fit(p2),
      fit(p3),
      fit(p4),
      fit(p5),
      fit(p6),
      fit(p7),
      fit(p8),
      fit(p9),
      fit(p10),
      fit(p11),
      fit(p12),
      fit(p13),
      fit(p14),
      fit(p15),
      fit(p16),
    ];

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    canvas.drawCircle(Offset(cx, 92), 62, glowPaint);

    final linePaint = Paint()
      ..color = AppColors.skeletonLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = AppColors.skeletonPoint
      ..style = PaintingStyle.fill;

    void connect(int a, int b) {
      canvas.drawLine(points[a], points[b], linePaint);
    }

    // head
    connect(0, 1);
    connect(1, 2);
    connect(2, 3);
    connect(3, 4);

    // upper body
    connect(5, 6);
    connect(5, 7);
    connect(7, 9);
    connect(6, 8);
    connect(8, 10);

    // torso
    connect(5, 11);
    connect(6, 12);
    connect(11, 12);

    // legs
    connect(11, 13);
    connect(13, 15);
    connect(12, 14);
    connect(14, 16);

    for (final p in points) {
      canvas.drawCircle(p, 6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}