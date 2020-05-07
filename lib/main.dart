import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  home: Container(color: Colors.grey[900], child: App()),
  debugShowCheckedModeBanner: false,
));

final random = Random();

final size = ui.window.physicalSize / ui.window.devicePixelRatio;

const frequency = Duration(milliseconds: 50);

final red = Paint()..color = Colors.red;
final redStroke = Paint()
  ..color = Colors.red
  ..style = PaintingStyle.stroke;

final black = Paint()..color = Colors.black;

class Circle {
  final Offset offset;
  final double radius;
  final Color color;

  const Circle({this.offset, this.color = Colors.white, this.radius = 10});
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final StreamController<List<Circle>> _circleStreamer =
  StreamController<List<Circle>>.broadcast();

  Stream<List<Circle>> get _circle$ => _circleStreamer.stream;

  Timer timer;

  final points = <Offset>[Offset.zero];
  final circles = <Circle>[];

  Offset force = Offset(10, 5);

  HSLColor color = HSLColor.fromColor(Colors.red);

  Offset get randomPoint => size.topLeft(Offset.zero) * random.nextDouble();

  @override
  void initState() {
    timer = Timer.periodic(
      frequency,
          (t) {
        if (circles.isEmpty)
          _circleStreamer.add(
            circles
              ..add(
                Circle(
                  offset:  size.topLeft(Offset.zero) * random.nextDouble(),
                  radius: random.nextDouble() * 10,
                  color: color.toColor().withOpacity(random.nextDouble()),
                ),
              ),
          );
        int count = 0;
        while (count < 5) {
          final dx = circles.last.offset.dx;
          final dy = circles.last.offset.dy;

          if ((dx + force.dx > size.width) || (dx + force.dx < 0))
            force = Offset(-force.dx, force.dy);
          if ((dy + force.dy > size.height) || (dy + force.dy < 0))
            force = Offset(force.dx, -force.dy);

          final newPoint = size.bottomRight(Offset.zero) * 0.5 +
              (size.bottomRight(Offset.zero) * 0.1)
                  .scale(cos(circles.length / 299), sin(circles.length / 299));

          final newCircle = Circle(
            offset: newPoint,
            radius: size.width / 30 +
                (size.height / 30 * sin(circles.length / 59)),
            color: color.toColor(),
          );
          color = color.withHue((color.hue + 0.2) % 360).withLightness(
              min(1.0, .1 + sin(circles.length / 59).abs() / 10));
          _circleStreamer.add(circles..add(newCircle));
          count++;
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    _circleStreamer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      StreamBuilder<List<Circle>>(
        initialData: [],
        stream: _circle$.map((event) => event.length > 20
            ? event.getRange(event.length - 20, event.length).toList()
            : event),
        builder: (context, snapshot) {
          final circles = snapshot.data;
          return RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: RectPainter(circles: circles),
            ),
          );
        },
      ),
    ],
  );
}

class RectPainter extends CustomPainter {
  List<Circle> circles;

  static final Paint dummyRectPaint = Paint()
    ..color = Color.fromARGB(0, 255, 255, 255)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.0;

  RectPainter({this.circles});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, dummyRectPaint);
    for (int i = 0; i < circles.length - 1; i++) {
      final c = circles[i];
      final hsl = HSLColor.fromColor(c.color);
      final paint = Paint()
        ..color = c.color
        ..shader = ui.Gradient.linear(
          c.offset,
          c.offset + Offset(0, c.radius),
          [
            c.color /*.withOpacity(0.5)*/,
            hsl.withLightness(max(0, min(1, hsl.lightness + 0.3))).toColor(),
          ],
        );
      final light = Paint()
            ..color = c.color
            ..shader = ui.Gradient.linear(
              c.offset,
              c.offset + Offset(0, c.radius),
              [
                Color(0x11ffffff),
                Color(0x11000000),
              ],
            );
//      canvas.drawCircle(c.offset, c.radius, light);
      canvas.drawRect(
          Rect.fromCircle(center: c.offset, radius: c.radius), paint);
      canvas.rotate(0.05);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
