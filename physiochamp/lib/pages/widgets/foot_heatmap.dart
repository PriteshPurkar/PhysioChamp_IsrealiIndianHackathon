import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'foot_layouts.dart';

/// FootHeatmapPainter40
/// Draws a human insole outline and 40 sensor blobs/color using RAW values.
/// Pass [minV,maxV] to match backend scale (e.g. 0..400).
class FootHeatmapPainter40 extends CustomPainter {
  final List<double> values; // length 40
  final bool isRight;
  final double minV;
  final double maxV;
  final bool showDots;

  FootHeatmapPainter40(
      this.values, {
        required this.isRight,
        this.minV = 0.0,
        this.maxV = 400.0,
        this.showDots = false, required positions,
      });

  @override
  void paint(Canvas canvas, Size size) {
    final path = isRight ? buildRightSolePath(size) : buildLeftSolePath(size);

    // Background
    final bg = Paint()..color = const Color(0xFFF6F6FA);
    canvas.drawPath(path, bg);

    // Clip to outline for nice heat glow
    canvas.save();
    canvas.clipPath(path);

    // Draw heat blobs
    final positions = isRight ? SENSOR_POSITIONS_RIGHT : SENSOR_POSITIONS_LEFT;
    final radius = kSensorRadiusNorm * min(size.width, size.height); // base dot size
    final blurRadius = radius * 2.2;

    // Use a layer so blurs and alpha accumulate cleanly
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());

    for (int i = 0; i < 40; i++) {
      final idx = i + 1;
      final pos = positions[idx]!;
      final c = Offset(pos.dx * size.width, pos.dy * size.height);

      final v = (i < values.length) ? values[i] : 0.0;
      final t = ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);

      if (t <= 0) continue;

      // Color ramp: blue -> cyan -> yellow -> orange -> red
      final color = _colorRamp(t);

      final paint = Paint()
        ..color = color.withOpacity(0.65)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

      // big soft blob
      canvas.drawCircle(c, radius * 2.8, paint);

      // a crisper inner blob to help definition
      final corePaint = Paint()
        ..color = color.withOpacity(0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.4);
      canvas.drawCircle(c, radius * 1.3, corePaint);
    }

    canvas.restore(); // end layer + clip

    // Outline stroke
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.black12;
    canvas.drawPath(path, stroke);

    // Optional sensor centers
    if (showDots) {
      final dotPaint = Paint()..color = Colors.black54;
      for (final e in positions.entries) {
        final p = Offset(e.value.dx * size.width, e.value.dy * size.height);
        canvas.drawCircle(p, radius * 0.45, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FootHeatmapPainter40 old) {
    // repaint on value/scale/foot changes
    return old.isRight != isRight ||
        old.minV != minV ||
        old.maxV != maxV ||
        !_listEq(old.values, values);
  }

  static bool _listEq(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 1e-9) return false;
    }
    return true;
  }

  // Smooth 5-stop ramp (blue → cyan → yellow → orange → red)
  Color _colorRamp(double t) {
    final stops = [
      const Color(0xFFBFD7FF), // blue-ish
      const Color(0xFF5BD4F5), // cyan
      const Color(0xFFFFE274), // yellow
      const Color(0xFFFF9A5C), // orange
      const Color(0xFFE53935), // red
    ];
    final n = stops.length - 1;
    final scaled = t * n;
    final i = scaled.floor().clamp(0, n - 1);
    final frac = (scaled - i).clamp(0.0, 1.0);
    return _lerpColor(stops[i], stops[i + 1], frac);
  }

  Color _lerpColor(Color a, Color b, double t) {
    return Color.fromARGB(
      (a.alpha + (b.alpha - a.alpha) * t).round(),
      (a.red + (b.red - a.red) * t).round(),
      (a.green + (b.green - a.green) * t).round(),
      (a.blue + (b.blue - a.blue) * t).round(),
    );
  }
}