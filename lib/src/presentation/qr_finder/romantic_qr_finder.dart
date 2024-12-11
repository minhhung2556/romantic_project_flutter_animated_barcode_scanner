import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// [RomanticQRFinder] : basic design for QR scanner.
/// [apertureEdge] : margin of [CameraPreview] to the screen.
/// [viewFinderEdge] : center of camera let the users places to the QR code picture, it is the length of white border lines.
/// [child] : is front of this, and inside the  finder rectangle.
class RomanticQRFinder extends StatelessWidget {
  final double apertureEdge;
  final double viewFinderEdge;
  final Color borderColor;
  final Widget? child;
  final double borderStrokeWidth;
  final Color lineColor;
  final double lineStrokeWidth;

  const RomanticQRFinder({
    super.key,
    this.apertureEdge = 32.0,
    this.viewFinderEdge = 48.0,
    this.child,
    this.borderColor = Colors.white,
    this.borderStrokeWidth = 2,
    this.lineColor = Colors.white,
    this.lineStrokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final qrFinderRectDimension =
        MediaQuery.of(context).size.shortestSide - apertureEdge * 2;
    return Stack(
      children: [
        Stack(
          fit: StackFit.expand,
          children: [
            // background
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5), BlendMode.srcOut),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut),
                  ),
                  // add a mask for qr finder rectangle.
                  Center(
                    child: Container(
                      width: qrFinderRectDimension,
                      height: qrFinderRectDimension,
                      color: borderColor, // any color.
                    ),
                  ),
                ],
              ),
            ),
            _buildBorders(context),
            if (child != null) child!,
          ],
        ),
        Padding(
          padding: EdgeInsets.all(apertureEdge + 4),
          child: GradientLineFinder(
            lineColor: lineColor,
            lineStrokeWidth: lineStrokeWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildBorders(BuildContext context) {
    final qrFinderRectDimension =
        MediaQuery.of(context).size.shortestSide - apertureEdge * 2;
    final x = max(0.0, qrFinderRectDimension - viewFinderEdge);
    return Stack(
      children: [
        // top-right border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(left: x, bottom: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 2),
                right: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
        // top-left border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(right: x, bottom: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 2),
                left: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
        // bottom-right border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(left: x, top: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 2),
                right: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
        // bottom-left border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(right: x, top: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 2),
                left: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
      ],
    );
  }
}

class GradientLineFinder extends StatefulWidget {
  final Color lineColor;
  final double lineStrokeWidth;

  const GradientLineFinder({
    super.key,
    this.lineColor = Colors.white,
    this.lineStrokeWidth = 2,
  });

  @override
  State<GradientLineFinder> createState() => _GradientLineFinderState();
}

class _GradientLineFinderState extends State<GradientLineFinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _controller.addListener(() {
      setState(() {});
    });
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      return Transform.translate(
        offset: ui.Offset(
            0.0,
            h *
                Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeInOutQuart))
                    .evaluate(_controller)),
        child: Container(
          color: widget.lineColor,
          width: double.infinity,
          height: widget.lineStrokeWidth,
        ),
      );
    });
  }
}

class GradientLinePainter extends CustomPainter {
  final Color startColor;
  final Color endColor;

  GradientLinePainter({
    this.startColor = Colors.transparent,
    this.endColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGradient = Paint()
      ..shader = ui.Gradient.linear(
        size.topCenter(ui.Offset.zero),
        size.bottomCenter(ui.Offset.zero),
        [
          Colors.transparent,
          Colors.white,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintGradient);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
