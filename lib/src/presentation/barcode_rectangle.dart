import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animated_qr_scanner/flutter_animated_qr_scanner.dart';

class BarcodeRectangle extends StatefulWidget {
  /// The four corner points of the barcode, in clockwise order starting with the top left relative to the detected image in the view coordinate system.
  ///
  /// Due to the possible perspective distortions, this is not necessarily a rectangle.
  final List<Point<int>> cornerPoints;

  /// The rectangle that holds the discovered barcode relative to the detected image in the view coordinate system.
  ///
  /// If nothing found it returns a rectangle with left, top, right, and bottom edges all at zero. `Rect.zero`.
  final Rect boundingBox;
  final Size imageSize;
  final Duration animationDuration;

  BarcodeRectangle({
    required this.cornerPoints,
    required this.boundingBox,
    required this.imageSize,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  State<BarcodeRectangle> createState() => _BarcodeRectangleState();
}

class _BarcodeRectangleState extends State<BarcodeRectangle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final qrFinderKey = GlobalKey();
  Animation<Rect?>? _rectAnimation;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.animationDuration);
    _controller.forward();


    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    print('BarcodeRectangle.build: screenSize=$screenSize, devicePixelRatio=$devicePixelRatio');
if(_rectAnimation == null && qrFinderKey.currentContext!=null){
  _rectAnimation = RectTween(
      begin: qrFinderKey.currentContext!.findRenderObject()!.paintBounds,
      end: Rect.fromLTRB(widget.cornerPoints[0].x.toDouble(), widget.cornerPoints[0].y.toDouble(),
          widget.cornerPoints[2].x.toDouble(), widget.cornerPoints[2].y.toDouble()))
      .animate(_controller);
}
    return Stack(
      children: [
        _rectAnimation == null
            ? SizedBox()
            : CustomPaint(
                size: screenSize,
                painter: BarcodePainter(
                  cornerPoints: [
                    Point(_rectAnimation!.value!.left.round(), _rectAnimation!.value!.top.round()),
                    Point(_rectAnimation!.value!.right.round(), _rectAnimation!.value!.top.round()),
                    Point(_rectAnimation!.value!.right.round(), _rectAnimation!.value!.bottom.round()),
                    Point(_rectAnimation!.value!.left.round(), _rectAnimation!.value!.bottom.round()),
                  ],
                  imageSize: widget.imageSize,
                ),
              ),
        Center(
          key: qrFinderKey,
          child: SizedBox(
            width: screenSize.width * 0.5,
            height: screenSize.width * 0.5,
            child: AnimatedQRFinder(),
          ),
        ),
      ],
    );
  }
}

class BarcodePainter extends CustomPainter {
  final List<Point<int>> cornerPoints;
  final Size imageSize;

  BarcodePainter({
    required this.imageSize,
    required this.cornerPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    //QR rect
    double scaleX = size.width / imageSize.width;
    double scaleY = size.height / imageSize.height;
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(cornerPoints[0].x * scaleX, cornerPoints[0].y * scaleY)
      ..lineTo(cornerPoints[1].x * scaleX, cornerPoints[1].y * scaleY)
      ..lineTo(cornerPoints[2].x * scaleX, cornerPoints[2].y * scaleY)
      ..lineTo(cornerPoints[3].x * scaleX, cornerPoints[3].y * scaleY)
      ..close();
    canvas.drawPath(path, paint);

    // widget rect
    final paint1 = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

extension RectConverter on Rect {
  Rect toDestinationRect({
    required Size originalParentSize,
    required Size widgetSize,
  }) {
    double scaleX = widgetSize.width / originalParentSize.width;
    double scaleY = widgetSize.height / originalParentSize.height;
    return Rect.fromLTRB(
      left * scaleX,
      top * scaleY,
      right * scaleX,
      bottom * scaleY,
    );
  }
}
