import 'package:compass/math_helper.dart';
import 'package:compass/sensor_data_affine.dart';
import 'package:compass/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:compass/face_variation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latext/latext.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    double compassWidth = MediaQuery.of(context).size.width * 0.74;
    return MaterialApp(
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
              backgroundColor: kBackground, foregroundColor: kForeground),
          scaffoldBackgroundColor: kBackground,
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRRectArc)),
                  side: const BorderSide(color: kForeground, width: 1.5),
                  foregroundColor: kForeground))),
      debugShowCheckedModeBanner: false,
      home: SafeArea(
          child: Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 60),
              SizedBox(
                width: compassWidth,
                height: compassWidth,
                child: CustomPaint(
                  painter: DefaultCompassPainter(),
                ),
              ),
              const SizedBox(height: 60),
              const Expanded(child: _HeadingIndicator()),
            ],
          ),
        ),
      )),
    );
  }
}

class _HeadingIndicator extends StatefulWidget {
  const _HeadingIndicator();

  @override
  State<_HeadingIndicator> createState() => _HeadingIndicatorState();
}

class _HeadingIndicatorState extends State<_HeadingIndicator> {
  SensorData? _magne;
  SensorData? _gyros;
  SensorData? _accel;
  static const int kDeltaT = 70; // ms

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
    double? deg;
    if (_magne != null) {
      deg = azimuth(_magne!);
      deg = deg - 90 >= 0 ? deg - 90 : deg + 271;
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text.rich(
              TextSpan(children: <InlineSpan>[
                TextSpan(
                    text: deg == null ? "\n" : "${deg.toStringAsFixed(1)}°\n",
                    style: const TextStyle(
                        fontSize: 46, fontWeight: FontWeight.bold)),
                const TextSpan(
                    text: "θ\nHeading\n\n",
                    style: TextStyle(fontSize: 14, color: kSecondary)),
                TextSpan(
                    text: _magne == null
                        ? "\n"
                        : strength(_magne!).toStringAsFixed(1)),
                if (_magne != null)
                  const TextSpan(
                      text: "\t\tμT\n", style: TextStyle(fontSize: 14)),
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
                                  AppBar(title: const Text("Sensor Values")),
                              body: Row(
                                children: <Widget>[
                                  const Spacer(),
                                  _SensorRealTimeData(
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
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _SensorRealTimeData extends StatelessWidget {
  const _SensorRealTimeData({
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
          const SizedBox(height: 30),
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
