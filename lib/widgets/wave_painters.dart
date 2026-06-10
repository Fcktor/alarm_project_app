import 'dart:math';
import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  const WavePainter({
    this.lines = 38,
    this.opacity = 0.13,
    this.strokeWidth = 1.2,
    this.ampBase = 3.5,
    this.ampFactor = 5.5,
    this.iFreqFactor = 0.9,
    this.iPhaseOffset = 1.2,
    this.freqBase = 0.055,
    this.freqStep = 0.008,
    this.freqMod = 6,
    this.xPhase = 0.75,
  });

  final int lines;
  final double opacity;
  final double strokeWidth;
  final double ampBase;
  final double ampFactor;
  final double iFreqFactor;
  final double iPhaseOffset;
  final double freqBase;
  final double freqStep;
  final int freqMod;
  final double xPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < lines; i++) {
      final x = size.width * i / lines;
      final path = Path();
      path.moveTo(x, 0);
      for (double y = 0; y <= size.height; y += 2) {
        final amp = ampBase + sin(i * iFreqFactor + iPhaseOffset) * ampFactor;
        final freq = freqBase + (i % freqMod) * freqStep;
        path.lineTo(x + sin(y * freq + i * xPhase) * amp, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
