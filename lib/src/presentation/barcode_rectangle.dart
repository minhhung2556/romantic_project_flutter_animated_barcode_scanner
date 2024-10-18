import 'dart:math';

import 'package:flutter/material.dart';

class BarcodeRectangle extends StatelessWidget {
  /// The four corner points of the barcode, in clockwise order starting with the top left relative to the detected image in the view coordinate system.
  ///
  /// Due to the possible perspective distortions, this is not necessarily a rectangle.
  final List<Point<int>> cornerPoints;

  /// The rectangle that holds the discovered barcode relative to the detected image in the view coordinate system.
  ///
  /// If nothing found it returns a rectangle with left, top, right, and bottom edges all at zero. `Rect.zero`.
  final Rect boundingBox;
  final Size imageSize;

  BarcodeRectangle({required this.cornerPoints, required this.boundingBox, required this.imageSize});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    debugPrint(
        'BarcodeRectangle.build: imageSize=$imageSize, screenSize=$screenSize, cornerPoints=$cornerPoints, boundingBox=$boundingBox');
    debugPrint('BarcodeRectangle.build: boundingBoxSize=${boundingBox.size}');
    return CustomPaint(
      size: screenSize,
      painter: BarcodePainter(
        cornerPoints: cornerPoints,
        screenSize: screenSize,
        boundingBox: boundingBox,
        imageSize: imageSize,
      ),
    );
  }
}

class BarcodePainter extends CustomPainter {
  final List<Point<int>> cornerPoints;
  final Rect boundingBox;
  final Size screenSize;
  final Size imageSize;
  BarcodePainter({
    required this.imageSize,
    required this.cornerPoints,
    required this.screenSize,
    required this.boundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
        Offset.zero,
        5,
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill
          ..strokeWidth = 1);

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final List<Offset> points = cornerPoints.map((imagePoint) {
      final scalePoint = ImageToScreenConverter.convertToScreenPoint(
          imagePoint: Offset(imagePoint.x.toDouble(), imagePoint.y.toDouble()),
          imageSize: boundingBox.size,
          screenSize: screenSize);
      return scalePoint;
    }).toList();

    /*if (points.length == 4) {
      final path = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy)
        ..lineTo(points[2].dx, points[2].dy)
        ..lineTo(points[3].dx, points[3].dy)
        ..close();
      canvas.drawPath(path, paint);
    }*/

    final scaledRect =
        RectConverter.convertToWidgetRect(imageRect: boundingBox, imageSize: imageSize, widgetSize: screenSize);
    canvas.drawRect(scaledRect, paint);

    canvas.drawRect(boundingBox, paint..color = Colors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ImageToScreenConverter {
  // Convert from image point to screen point
  static Offset convertToScreenPoint({
    required Offset imagePoint,
    required Size imageSize,
    required Size screenSize,
  }) {
    double scaleX = screenSize.width / imageSize.width;
    double scaleY = screenSize.height / imageSize.height;
    return Offset(imagePoint.dx * scaleX, imagePoint.dy * scaleY);
  }
}

class RectConverter {
  static Rect convertToWidgetRect({
    required Rect imageRect,
    required Size imageSize,
    required Size widgetSize,
  }) {
    double scaleX = widgetSize.width / imageSize.width;
    double scaleY = widgetSize.height / imageSize.height;
    return Rect.fromLTRB(
      imageRect.left * scaleX,
      imageRect.top * scaleY,
      imageRect.right * scaleX,
      imageRect.bottom * scaleY,
    );
  }
}
