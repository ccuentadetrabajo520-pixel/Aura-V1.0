import 'package:flutter/material.dart';

class AuraRadarWaves extends StatelessWidget {
  final Animation<double> animation;
  final Color themeColor;

  const AuraRadarWaves({
    Key? key,
    required this.animation,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AuraRadarPainter(
        animation: animation,
        themeColor: themeColor,
      ),
      size: const Size(320, 380),
    );
  }
}

class AuraRadarPainter extends CustomPainter {
  final Animation<double> animation;
  final Color themeColor;

  AuraRadarPainter({
    required this.animation,
    required this.themeColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var index = 0; index < 3; index++) {
      final progress = (animation.value + index / 3) % 1.0;
      final paint = Paint()
        ..color = themeColor.withValues(
          alpha: ((1.0 - progress) * 0.25).clamp(0.0, 0.25).toDouble(),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, maxRadius * progress, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AuraRadarPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.themeColor != themeColor;
}
