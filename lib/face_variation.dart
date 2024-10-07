import 'dart:math';

import 'package:compass/math_helper.dart';
import 'package:compass/shared.dart';
import 'package:flutter/material.dart';

class DefaultCompassPainter extends CustomPainter {
  double northAngle;

  DefaultCompassPainter({this.northAngle = 0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = kMajorHeadings
      ..strokeWidth = 8
      ..filterQuality = FilterQuality.high
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(MathUtil.degToRads(270));
    canvas.translate(-size.width / 2, -size.height / 2);
    double radius = size.width / 2;
    Offset center = Offset(size.width / 2, size.height / 2);
    paint.color = kNorthSide;
    canvas.drawLine(
        Offset(center.dx + radius * cos(MathUtil.degToRads(northAngle)),
            center.dy + radius * sin(MathUtil.degToRads(northAngle))),
        Offset(center.dx + (radius - 34) * cos(MathUtil.degToRads(northAngle)),
            center.dy + (radius - 34) * sin(MathUtil.degToRads(northAngle))),
        paint);
    paint.color = kMajorHeadings;
    for (int i = 90; i < 360; i += 90) {
      double angle = MathUtil.degToRads(i.toDouble());
      canvas.drawLine(
          Offset(
              center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
          Offset(center.dx + (radius - 34) * cos(angle),
              center.dy + (radius - 34) * sin(angle)),
          paint);
    }
    paint.color = kMinorHeadings;
    paint.strokeWidth = 6;
    for (int i = 0; i < 360; i += 45) {
      double angle = MathUtil.degToRads(i.toDouble());
      if (i % 90 == 0) {
        continue;
      } else {
        canvas.drawLine(
            Offset(center.dx + radius * cos(angle),
                center.dy + radius * sin(angle)),
            Offset(center.dx + (radius - 18) * cos(angle),
                center.dy + (radius - 18) * sin(angle)),
            paint);
      }
    }
    paint.color = kHeadings;
    paint.strokeWidth = 4;
    for (int i = 0; i < 360; i += 15) {
      double angle = MathUtil.degToRads(i.toDouble());
      if (i % 45 == 0) {
        continue;
      } else {
        canvas.drawLine(
            Offset(center.dx + radius * cos(angle),
                center.dy + radius * sin(angle)),
            Offset(center.dx + (radius - 8) * cos(angle),
                center.dy + (radius - 8) * sin(angle)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


