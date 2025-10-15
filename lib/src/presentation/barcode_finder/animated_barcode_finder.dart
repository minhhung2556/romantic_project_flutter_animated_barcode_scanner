import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A widget that displays a barcode finder with an animated border and a
/// scanning line.
///
/// This widget creates a square viewfinder area with a semi-transparent overlay
/// on the rest of the screen. It includes animated corner borders and an
/// optional animated line that sweeps across the viewfinder.
///
/// Use the [AnimatedBarcodeFinder.static] constructor to create a finder
/// without animations.
class AnimatedBarcodeFinder extends StatelessWidget {
  /// An optional widget to display on top of the finder overlay.
  ///
  /// This widget is placed behind the viewfinder rectangle but in front of the camera preview.
  final Widget? child;

  final double apertureEdge;
  final double viewFinderEdge;

  final Color borderColor;
  final double borderStrokeWidth;
  final Duration borderAnimationDuration;
  final Curve borderAnimationCurve;
  final double borderAnimationDelta;

  final bool hasLine;
  final Color lineColor;
  final double lineStrokeWidth;
  final EdgeInsets lineMargin;
  final Duration lineAnimationDuration;
  final Curve lineAnimationCurve;

  /// Constructor.
  const AnimatedBarcodeFinder({
    super.key,
    this.child,
    this.apertureEdge = 48.0,
    this.viewFinderEdge = 32.0,
    this.borderColor = Colors.white,
    this.borderStrokeWidth = 2,
    this.borderAnimationDuration = const Duration(milliseconds: 300),
    this.borderAnimationCurve = Curves.easeInOutQuart,
    this.borderAnimationDelta = 5,
    this.lineColor = Colors.white,
    this.lineStrokeWidth = 2,
    this.lineAnimationDuration = const Duration(milliseconds: 1000),
    this.lineAnimationCurve = Curves.easeInOutQuart,
    this.lineMargin = const EdgeInsets.all(2),
    this.hasLine = true,
  });

  /// Create an AnimatedQRFinder without animation.
  const AnimatedBarcodeFinder.static({
    super.key,
    this.child,
    this.apertureEdge = 48.0,
    this.viewFinderEdge = 32.0,
    this.borderColor = Colors.white,
    this.borderStrokeWidth = 2,
    this.borderAnimationDelta = 5,
    this.lineColor = Colors.white,
    this.lineStrokeWidth = 2,
    this.lineMargin = const EdgeInsets.all(2),
    this.hasLine = true,
  })  : lineAnimationDuration = Duration.zero,
        lineAnimationCurve = Curves.linear,
        borderAnimationDuration = Duration.zero,
        borderAnimationCurve = Curves.linear;

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
              colorFilter:
                  const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
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
              curve: borderAnimationCurve,
              duration: borderAnimationDuration,
              delta: borderAnimationDelta,
            ),
            if (child != null) child!,
          ],
        ),
        if (hasLine)
          Padding(
            padding: EdgeInsets.all(apertureEdge) + lineMargin,
            child: _AnimatedBarcodeScannerLine(
              lineColor: lineColor,
              lineStrokeWidth: lineStrokeWidth,
              apertureEdge: apertureEdge,
              duration: lineAnimationDuration,
              curve: lineAnimationCurve,
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
  final Duration duration;
  final Curve curve;

  const _AnimatedBarcodeScannerLine({
    required this.lineColor,
    required this.lineStrokeWidth,
    required this.apertureEdge,
    required this.duration,
    required this.curve,
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
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(() {
      setState(() {});
    });
    if (widget.duration > Duration.zero) {
      _controller.repeat(reverse: true);
    } else {
      // if [AnimatedQRFinder] has no line, or is static, then draw the line in center of the finder.
      _controller.value = 0.5;
    }
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
                .chain(CurveTween(curve: widget.curve))
                .evaluate(_controller),
      ),
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
  final Duration duration;
  final double delta;
  final Curve curve;

  const _AnimatedBarcodeScannerBorders({
    required this.apertureEdge,
    required this.viewFinderEdge,
    required this.borderColor,
    required this.borderStrokeWidth,
    required this.lineColor,
    required this.lineStrokeWidth,
    required this.duration,
    required this.delta,
    required this.curve,
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
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(() {
      setState(() {});
    });
    if (widget.duration > Duration.zero) {
      _controller.repeat(reverse: true);
    } else {
      // if [AnimatedQRFinder] is static, then draw the border without adding [delta].
      _controller.value = 0.5;
    }
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
        Tween<double>(begin: -widget.delta, end: widget.delta)
            .chain(CurveTween(curve: widget.curve))
            .evaluate(_controller);
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
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
                right: BorderSide(
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
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
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
                left: BorderSide(
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
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
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
                right: BorderSide(
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
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
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
                left: BorderSide(
                  color: widget.borderColor,
                  width: widget.borderStrokeWidth,
                ),
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
