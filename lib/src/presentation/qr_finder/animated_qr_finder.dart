import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// [AnimatedQRFinder] : basic design for QR scanner.
/// [apertureEdge] : margin of [CameraPreview] to the screen.
/// [viewFinderEdge] : center of camera let the users places to the QR code picture, it is the length of white border lines.
/// [child] : is front of this, and inside the  finder rectangle.
class AnimatedQRFinder extends StatelessWidget {
  final Widget? child;
  final double apertureEdge;
  final double viewFinderEdge;
  final Color borderColor;
  final double borderStrokeWidth;
  final Color lineColor;
  final double lineStrokeWidth;

  const AnimatedQRFinder({
    super.key,
    this.child,
    this.apertureEdge = 48.0,
    this.viewFinderEdge = 32.0,
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
      alignment: Alignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // background
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcOut),
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
            _AnimatedBarcodeScannerBorders(
              apertureEdge: apertureEdge,
              viewFinderEdge: viewFinderEdge,
              lineColor: lineColor,
              lineStrokeWidth: lineStrokeWidth,
              borderColor: borderColor,
              borderStrokeWidth: borderStrokeWidth,
            ),
            if (child != null) child!,
          ],
        ),
        Padding(
          padding: EdgeInsets.all(apertureEdge),
          child: _AnimatedBarcodeScannerLine(
            lineColor: lineColor,
            lineStrokeWidth: lineStrokeWidth,
            apertureEdge: apertureEdge,
          ),
        ),
      ],
    );
  }
}

class _AnimatedBarcodeScannerLine extends StatefulWidget {
  final Color lineColor;
  final double lineStrokeWidth;
  final double apertureEdge;

  const _AnimatedBarcodeScannerLine({
    this.lineColor = Colors.white,
    this.lineStrokeWidth = 2,
    this.apertureEdge = 0,
  });

  @override
  State<_AnimatedBarcodeScannerLine> createState() =>
      _AnimatedBarcodeScannerLineState();
}

class _AnimatedBarcodeScannerLineState
    extends State<_AnimatedBarcodeScannerLine>
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
    final size = MediaQuery.of(context).size;
    //qr finder is a rectangle with dimension is shortest side.
    final h =
        size.shortestSide - (widget.apertureEdge + widget.lineStrokeWidth) * 2;
    return Transform.translate(
      offset: ui.Offset(
          0.0,
          h *
              Tween(begin: -0.5, end: 0.5)
                  .chain(CurveTween(curve: Curves.easeInOutQuart))
                  .evaluate(_controller)),
      child: Container(
        color: widget.lineColor,
        width: double.infinity,
        height: widget.lineStrokeWidth,
      ),
    );
  }
}

class _AnimatedBarcodeScannerBorders extends StatefulWidget {
  final double apertureEdge;
  final double viewFinderEdge;
  final Color borderColor;
  final double borderStrokeWidth;
  final Color lineColor;
  final double lineStrokeWidth;

  const _AnimatedBarcodeScannerBorders({
    this.apertureEdge = 0,
    this.viewFinderEdge = 1,
    this.borderColor = Colors.white,
    this.borderStrokeWidth = 2,
    this.lineColor = Colors.white,
    this.lineStrokeWidth = 2,
  });

  @override
  State<_AnimatedBarcodeScannerBorders> createState() =>
      _AnimatedBarcodeScannerBordersState();
}

class _AnimatedBarcodeScannerBordersState
    extends State<_AnimatedBarcodeScannerBorders>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
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
    final qrFinderRectDimension =
        MediaQuery.of(context).size.shortestSide - widget.apertureEdge * 2;
    final x = max(0.0, qrFinderRectDimension - widget.viewFinderEdge) +
        Tween<double>(begin: -5, end: 5).evaluate(_controller);
    return Stack(
      children: [
        // top-right border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(left: x, bottom: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
                right: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
              ),
            ),
            width: widget.viewFinderEdge,
            height: widget.viewFinderEdge,
          ),
        ),
        // top-left border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(right: x, bottom: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
                left: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
              ),
            ),
            width: widget.viewFinderEdge,
            height: widget.viewFinderEdge,
          ),
        ),
        // bottom-right border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(left: x, top: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
                right: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
              ),
            ),
            width: widget.viewFinderEdge,
            height: widget.viewFinderEdge,
          ),
        ),
        // bottom-left border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(right: x, top: x),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
                left: BorderSide(
                    color: widget.borderColor, width: widget.borderStrokeWidth),
              ),
            ),
            width: widget.viewFinderEdge,
            height: widget.viewFinderEdge,
          ),
        ),
      ],
    );
  }
}
