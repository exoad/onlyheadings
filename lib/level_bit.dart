import 'package:compass/shared.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class RollPitchPainter extends CustomPainter {
  final double roll; // Roll angle in radians
  final double pitch; // Pitch angle in radians

  RollPitchPainter(this.roll, this.pitch);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double pitchX = centerX;
    final double pitchY = centerY - (pitch * 100);
    paint.color = Colors.red;
    canvas.drawLine(Offset(centerX, centerY),
        Offset(centerX + (roll * 100), centerY), paint);
    paint.color = Colors.green;
    canvas.drawLine(Offset(centerX, centerY), Offset(pitchX, pitchY), paint);
    paint.strokeWidth = 2;
    paint.color = Colors.white;
    canvas.drawCircle(
        Offset(centerX + (roll * 100 * 0.69), centerY - (pitch * 100 * 0.69)),
        6,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint to reflect changes
  }
}
