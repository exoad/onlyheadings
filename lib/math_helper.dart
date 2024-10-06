import 'dart:math';

class MathUtil {
  MathUtil._();

  static double degToRads(double deg) => (deg * pi) / 180;

  static double radsToDeg(double rads) => (rads * 180) / pi;

  static double normalizeDeg(double deg) {
    double normalized = deg % 360;
    if (normalized < 0) {
      normalized += 360;
    }
    return normalized;
  }

  static double normalizeRads(double reds) {
    double normalized = reds % (2 * pi);
    if (normalized < 0) {
      normalized += 2 * pi;
    }
    return normalized;
  }
}
