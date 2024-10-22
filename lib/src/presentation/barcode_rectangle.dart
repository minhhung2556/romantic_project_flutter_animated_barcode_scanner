import 'package:flutter/material.dart';

class BarcodeRectangle extends StatefulWidget {
  final List<Offset> cornerPoints;
  final Size imageSize;
  final Color color;

  BarcodeRectangle({
    required this.cornerPoints,
    required this.imageSize,
    required this.color,
  });

  @override
  State<BarcodeRectangle> createState() => _BarcodeRectangleState();
}

class _BarcodeRectangleState extends State<BarcodeRectangle> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return CustomPaint(
      size: screenSize,
      painter: BarcodePainter(
        cornerPoints: widget.cornerPoints,
        imageSize: widget.imageSize,
        color: widget.color,
      ),
    );
  }
}

class BarcodePainter extends CustomPainter {
  final List<Offset> cornerPoints;
  final Size imageSize;
  final Color color;

  BarcodePainter({
    required this.imageSize,
    required this.cornerPoints,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    //QR rect
    double scaleX = size.width / imageSize.width;
    double scaleY = size.height / imageSize.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(cornerPoints[0].dx * scaleX, cornerPoints[0].dy * scaleY)
      ..lineTo(cornerPoints[1].dx * scaleX, cornerPoints[1].dy * scaleY)
      ..lineTo(cornerPoints[2].dx * scaleX, cornerPoints[2].dy * scaleY)
      ..lineTo(cornerPoints[3].dx * scaleX, cornerPoints[3].dy * scaleY)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
