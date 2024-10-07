import 'dart:math';

import 'package:compass/math_helper.dart';
import 'package:compass/sensor_data_affine.dart';
import 'package:compass/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:compass/face_variation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:latext/latext.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'level_bit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  FlutterDisplayMode.setHighRefreshRate().then((_) => runApp(const MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  SensorData? _magne;
  SensorData? _accel;
  double _currentHeading = 0;
  double _targetHeading = 0; // Target heading for smooth interpolation
  static const int kDeltaT = 160; // ms
  static double headingThreshold = 2.0;
  late AnimationController _controller;
  late Animation<double> _headingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kDeltaT),
    );
    _headingAnimation =
        Tween<double>(begin: _currentHeading, end: _currentHeading).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: kDeltaT),
    ).listen((MagnetometerEvent event) {
      setState(() {
        _magne = event.sensorData;
        _updateHeading();
      });
    });
    accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: kDeltaT))
        .listen((AccelerometerEvent event) {
      setState(() {
        _accel = event.sensorData;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateHeading() {
    if (_magne != null) {
      double newHeading = azimuth(_magne!);
      newHeading = (newHeading - 90) % 360;
      if (newHeading < 0) {
        newHeading += 360;
      }
      _targetHeading = _currentHeading +
          0.3 * (_calculateShortestRotation(_currentHeading, newHeading));
      double headingDifference =
          _calculateShortestRotation(_currentHeading, _targetHeading);
      if (headingDifference.abs() > headingThreshold) {
        _headingAnimation =
            Tween<double>(begin: _currentHeading, end: _targetHeading).animate(
                CurvedAnimation(parent: _controller, curve: Curves.linear));
        _controller.forward(from: 0.0);
        _currentHeading = _targetHeading;
        _currentHeading = _currentHeading % 360;
        if (_currentHeading < 0) {
          _currentHeading += 360;
        }
      }
    }
  }

  double _calculateShortestRotation(double current, double target) {
    double difference = target - current;
    if (difference > 180) {
      difference -= 360;
    } else if (difference < -180) {
      difference += 360;
    }
    return difference;
  }

  @override
  Widget build(BuildContext context) {
    double compassWidth = MediaQuery.of(context).size.width * 0.92;
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          foregroundColor: kForeground,
        ),
        scaffoldBackgroundColor: kBackground,
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRRectArc),
            ),
            side: const BorderSide(color: kForeground, width: 1.5),
            foregroundColor: kForeground,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: kBackground,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.arrow_drop_down_rounded,
                      size: 54, color: kForeground),
                  // Compass CustomPaint widget with rotation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass CustomPaint widget with rotation
                      RepaintBoundary(
                        child: SizedBox(
                          width: compassWidth,
                          height: compassWidth,
                          child: AnimatedBuilder(
                            animation: _headingAnimation,
                            builder: (BuildContext context, Widget? child) {
                              return Transform.rotate(
                                angle:
                                    _headingAnimation.value * (pi / 180) * -1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CustomPaint(
                                    painter: DefaultCompassPainter(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Roll and Pitch Indicator
                      if (_accel != null)
                        Center(
                          child: CustomPaint(
                            size: const Size(100, 100),
                            painter:
                                RollPitchPainter(roll(_accel!), pitch(_accel!)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Heading Indicator widget that shows the current heading
                  _HeadingIndicator(heading: _currentHeading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeadingIndicator extends StatefulWidget {
  final double heading;

  const _HeadingIndicator({required this.heading});

  @override
  State<_HeadingIndicator> createState() => _HeadingIndicatorState();
}

class _HeadingIndicatorState extends State<_HeadingIndicator> {
  SensorData? _magne;
  SensorData? _gyros;
  SensorData? _accel;
  static const int kDeltaT = 90; // ms

  @override
  void initState() {
    super.initState();
    magnetometerEventStream(
            samplingPeriod: const Duration(milliseconds: kDeltaT))
        .listen((MagnetometerEvent event) =>
            setState(() => _magne = event.sensorData));
    gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: kDeltaT))
        .listen((GyroscopeEvent event) =>
            setState(() => _gyros = event.sensorData));
    accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: kDeltaT))
        .listen((AccelerometerEvent event) =>
            setState(() => _accel = event.sensorData));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text.rich(
            TextSpan(children: <InlineSpan>[
              TextSpan(
                  text: "${widget.heading.abs().toStringAsFixed(0)}°\n",
                  style: const TextStyle(
                      fontSize: 46, fontWeight: FontWeight.bold, height: 0.8)),
              TextSpan(
                  text: toCardinalName(widget.heading.abs()),
                  style: const TextStyle(fontSize: 24)),
              const TextSpan(
                  text: "\nθ\nHeading\n\n",
                  style: TextStyle(fontSize: 14, color: kSecondary)),
              TextSpan(
                  text: _magne == null
                      ? "\n"
                      : " ${strength(_magne!).toStringAsFixed(1)}"),
              if (_magne != null)
                const TextSpan(
                    text: "\t\tμT\n", style: TextStyle(fontSize: 14)),
              if (_magne != null && strength(_magne!) > 70)
                const WidgetSpan(
                    child: Icon(Icons.warning_amber_outlined,
                        color: Colors.red, size: 18))
              else
                const WidgetSpan(
                    child: Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 18)),
              if (_magne != null && strength(_magne!) > 70)
                const TextSpan(
                    text: " Inaccurate\t\n",
                    style: TextStyle(fontSize: 11, color: Colors.red))
              else
                const TextSpan(
                    text: " Accurate\t\n",
                    style: TextStyle(fontSize: 11, color: Colors.green)),
              if (_magne != null)
                const TextSpan(
                    text: "H\nMagnetic Field Strength\n\n",
                    style: TextStyle(fontSize: 14, color: kSecondary)),
              TextSpan(
                  text: _accel == null
                      ? "\n"
                      : "${MathUtil.radsToDeg(pitch(_accel!)).toStringAsFixed(1)}°\n",
                  style: const TextStyle(height: 1)),
              const TextSpan(
                  text: "θ\nPitch\n\n",
                  style: TextStyle(fontSize: 14, color: kSecondary)),
              TextSpan(
                  text: _accel == null
                      ? "\n"
                      : "${MathUtil.radsToDeg(roll(_accel!)).toStringAsFixed(1)}°\n"),
              const TextSpan(
                  text: "φ\nRoll\n\n",
                  style: TextStyle(fontSize: 14, color: kSecondary)),
              TextSpan(
                  text: _gyros == null
                      ? "\n"
                      : "${MathUtil.radsToDeg(strength(_gyros!)).toStringAsFixed(1)} °/s\n"),
              const TextSpan(
                  text: "ω\nAngular Speed\n\n",
                  style: TextStyle(fontSize: 14, color: kSecondary))
            ]),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, color: kForeground)),
        SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.45,
            child: const Divider(color: kForeground)),
        const SizedBox(height: 20),
        OutlinedButton(
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                      builder: (BuildContext context) => Scaffold(
                            appBar:
                                AppBar(title: const Text("Calculations View")),
                            body: Row(
                              children: <Widget>[
                                const Spacer(),
                                SensorCalculationsView(
                                    gyros: _gyros,
                                    accel: _accel,
                                    magne: _magne),
                                const Spacer(),
                              ],
                            ),
                          )),
                ),
            child: const Text("View Sensor Details",
                style: TextStyle(fontSize: 18, color: kForeground))),
        const SizedBox(height: 20),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber, width: 1.5)),
            onPressed: () async => await launchUrl(
                Uri.parse("https://github.com/exoad/onlyheadings")),
            child: const Text("App Repository",
                style: TextStyle(fontSize: 18, color: Colors.amber))),
        const SizedBox(height: 60),
      ],
    );
  }
}

class SensorCalculationsView extends StatelessWidget {
  const SensorCalculationsView({
    super.key,
    required SensorData? gyros,
    required SensorData? accel,
    required SensorData? magne,
  })  : _gyros = gyros,
        _accel = accel,
        _magne = magne;

  final SensorData? _gyros;
  final SensorData? _accel;
  final SensorData? _magne;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 50),
          Text(DateTime.now().toIso8601String(),
              style: const TextStyle(fontSize: 26, color: kForeground)),
          const SizedBox(height: 26),
          LaTexT(
            laTeXCode: Text(
                "\$\\begin{bmatrix} \\omega_{x} \\\\ \\omega_{y} \\\\ \\omega_{z} \\end{bmatrix} = \\begin{bmatrix} ${_gyros!.x.toStringAsFixed(4)} \\\\ ${_gyros!.y.toStringAsFixed(4)} \\\\ ${_gyros!.z.toStringAsFixed(4)} \\end{bmatrix}\$",
                style: const TextStyle(fontSize: 30, color: kForeground)),
          ),
          const SizedBox(height: 54),
          LaTexT(
            laTeXCode: Text(
                "\$\\begin{bmatrix} a_{x} \\\\ a_{y} \\\\ a_{z} \\end{bmatrix} = \\begin{bmatrix} ${_accel!.x.toStringAsFixed(4)} \\\\ ${_accel!.y.toStringAsFixed(4)} \\\\ ${_accel!.z.toStringAsFixed(4)} \\end{bmatrix}\$",
                style: const TextStyle(fontSize: 30, color: kForeground)),
          ),
          const SizedBox(height: 54),
          LaTexT(
            laTeXCode: Text(
                "\$\\begin{bmatrix} B_{x} \\\\ B_{y} \\\\ B_{z} \\end{bmatrix} = \\begin{bmatrix} ${_magne!.x.toStringAsFixed(4)} \\\\ ${_magne!.y.toStringAsFixed(4)} \\\\ ${_magne!.z.toStringAsFixed(4)} \\end{bmatrix}\$",
                style: const TextStyle(fontSize: 30, color: kForeground)),
          ),
        ]);
  }
}
