// radar_waves.dart - Efectos de Ondas de Escaneo Perimetral
import 'package:flutter/material.dart';

class AuraRadarWaves extends StatelessWidget {
  final double animationValue;
  final Color themeColor;

  const AuraRadarWaves({
    Key? key,
    required this.animationValue,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (index) {
        double currentProgress = (animationValue + (index / 3)) % 1.0;
        return Opacity(
          opacity: (1.0 - currentProgress).clamp(0.0, 1.0),
          child: Container(
            width: 320 * currentProgress,
            height: 380 * currentProgress,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: themeColor.withOpacity(0.25),
                width: 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
