import 'dart:ui';

/// Human insole outline (smooth shoe-like), normalized [0..1] space.
Path buildLeftSolePath(Size size) {
  double x(double nx) => nx * size.width;
  double y(double ny) => ny * size.height;

  final p = Path()
    ..moveTo(x(0.50), y(0.02))
    ..cubicTo(x(0.78), y(0.04), x(0.90), y(0.10), x(0.92), y(0.20))
    ..cubicTo(x(0.94), y(0.30), x(0.88), y(0.38), x(0.82), y(0.44))
    ..cubicTo(x(0.74), y(0.52), x(0.74), y(0.60), x(0.80), y(0.70))
    ..cubicTo(x(0.86), y(0.84), x(0.72), y(0.98), x(0.50), y(0.99))
    ..cubicTo(x(0.28), y(0.98), x(0.14), y(0.84), x(0.20), y(0.70))
    ..cubicTo(x(0.26), y(0.60), x(0.26), y(0.52), x(0.18), y(0.44))
    ..cubicTo(x(0.10), y(0.38), x(0.06), y(0.30), x(0.08), y(0.20))
    ..cubicTo(x(0.10), y(0.10), x(0.22), y(0.04), x(0.50), y(0.02))
    ..close();
  return p;
}

Path buildRightSolePath(Size size) {
  double x(double nx) => (1.0 - nx) * size.width;
  double y(double ny) => ny * size.height;

  final p = Path()
    ..moveTo(x(0.50), y(0.02))
    ..cubicTo(x(0.78), y(0.04), x(0.90), y(0.10), x(0.92), y(0.20))
    ..cubicTo(x(0.94), y(0.30), x(0.88), y(0.38), x(0.82), y(0.44))
    ..cubicTo(x(0.74), y(0.52), x(0.74), y(0.60), x(0.80), y(0.70))
    ..cubicTo(x(0.86), y(0.84), x(0.72), y(0.98), x(0.50), y(0.99))
    ..cubicTo(x(0.28), y(0.98), x(0.14), y(0.84), x(0.20), y(0.70))
    ..cubicTo(x(0.26), y(0.60), x(0.26), y(0.52), x(0.18), y(0.44))
    ..cubicTo(x(0.10), y(0.38), x(0.06), y(0.30), x(0.08), y(0.20))
    ..cubicTo(x(0.10), y(0.10), x(0.22), y(0.04), x(0.50), y(0.02))
    ..close();
  return p;
}

/// 40-sensor LEFT layout in normalized coordinates (toe→heel rows).
const Map<int, Offset> SENSOR_POSITIONS_LEFT = {
  1: Offset(0.2828, 0.0800),
  2: Offset(0.5002, 0.0797),
  3: Offset(0.7168, 0.0809),

  4: Offset(0.2199, 0.1221),
  5: Offset(0.3930, 0.1217),
  6: Offset(0.6070, 0.1217),
  7: Offset(0.7815, 0.1232),

  8: Offset(0.2115, 0.1668),
  9: Offset(0.3942, 0.1672),
  10: Offset(0.6087, 0.1672),
  11: Offset(0.7908, 0.1676),

  12: Offset(0.2070, 0.2120),
  13: Offset(0.3931, 0.2120),
  14: Offset(0.6107, 0.2111),
  15: Offset(0.7976, 0.2124),

  16: Offset(0.2068, 0.2576),
  17: Offset(0.3940, 0.2571),
  18: Offset(0.6095, 0.2573),
  19: Offset(0.7980, 0.2576),

  20: Offset(0.2118, 0.3042),
  21: Offset(0.3979, 0.3032),
  22: Offset(0.6074, 0.3024),
  23: Offset(0.7883, 0.3032),

  24: Offset(0.3348, 0.3568),
  25: Offset(0.6712, 0.3560),

  26: Offset(0.3341, 0.4128),
  27: Offset(0.6710, 0.4124),

  28: Offset(0.3441, 0.4688),
  29: Offset(0.6612, 0.4692),

  30: Offset(0.2774, 0.5531),
  31: Offset(0.5023, 0.5523),
  32: Offset(0.7252, 0.5527),

  33: Offset(0.2668, 0.6090),
  34: Offset(0.5030, 0.6094),
  35: Offset(0.7390, 0.6094),

  36: Offset(0.2603, 0.6647),
  37: Offset(0.5035, 0.6647),
  38: Offset(0.7455, 0.6647),

  39: Offset(0.4041, 0.9304),
  40: Offset(0.5975, 0.9304),
};

/// Right = horizontal mirror of left layout
final Map<int, Offset> SENSOR_POSITIONS_RIGHT = {
  for (final e in SENSOR_POSITIONS_LEFT.entries)
    e.key: Offset(1.0 - e.value.dx, e.value.dy),
};

/// Normalized dot radius; scale by min(size.w, size.h) in painter
const double kSensorRadiusNorm = 0.028;