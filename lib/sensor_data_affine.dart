import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

double _kG = 9.81;

extension UsefulMagnetometerData on MagnetometerEvent {
  SensorData get sensorData => (x: x, y: y, z: z);
}

extension UsefulAccelerometerData on AccelerometerEvent {
  SensorData get sensorData => (x: x, y: y, z: z);
}

extension UsefulGyroscopeData on GyroscopeEvent {
  SensorData get sensorData => (x: x, y: y, z: z);
}

typedef SensorData = ({double x, double y, double z});

double pitch(SensorData data) =>
    atan2(data.y, sqrt((data.x * data.x) + (data.z * data.z)));

double roll(SensorData data) => atan2(-data.x, data.z);

double azimuth(SensorData data) {
  double t = atan2(data.y, data.x);
  return t >= 0 ? t * (180 / pi) : (t + 2 * pi) * (180 / pi);
}

double strength(SensorData data) =>
    sqrt((data.x * data.x) + (data.y * data.y) + (data.z * data.z));

({double uX, double uY, double uZ}) normalize(SensorData data) {
  double mag = strength(data);
  return (uX: data.x / mag, uY: data.y / mag, uZ: data.z / mag);
}

String toCardinalName(double heading) {
  heading = heading % 360;
  if (heading < 0) {
    heading += 360;
  }
  switch (heading) {
    case double h when (h >= 337.5 || h < 22.5):
      return "N ";
    case double h when (h >= 22.5 && h < 67.5):
      return "NE";
    case double h when (h >= 67.5 && h < 112.5):
      return "E ";
    case double h when (h >= 112.5 && h < 157.5):
      return "SE";
    case double h when (h >= 157.5 && h < 202.5):
      return "S ";
    case double h when (h >= 202.5 && h < 247.5):
      return "SW";
    case double h when (h >= 247.5 && h < 292.5):
      return "W";
    case double h when (h >= 292.5 && h < 337.5):
      return "NE";
    default:
      return "??";
  }
}