import 'package:flutter/material.dart';

/// Draw a rectangle outside of a barcode.
/// [cornerPoints] : corner points of the barcode on the image.
/// [imageSize] : size/resolution of the image, not the widget size.
/// [color] : color of rectangle.
/// [strokeWidth] : stroke width of [Paint] to draw.
class BasicBarcodeRectangle extends StatelessWidget {
  final List<Offset> cornerPoints;
  final Size imageSize;
  final Color color;
  final double strokeWidth;

  /// Constructor.
  const BasicBarcodeRectangle({
    super.key,
    required this.cornerPoints,
    required this.imageSize,
    required this.color,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: imageSize,
      painter: _BarcodePainter(
        cornerPoints: cornerPoints,
        imageSize: imageSize,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// Paint the rectangle of the barcode.
class _BarcodePainter extends CustomPainter {
  final List<Offset> cornerPoints;
  final Size imageSize;
  final Color color;
  final double strokeWidth;

  _BarcodePainter({
    required this.imageSize,
    required this.cornerPoints,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    //QR rect
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
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
    return true; // for realtime update the rectangle.
  }
}
