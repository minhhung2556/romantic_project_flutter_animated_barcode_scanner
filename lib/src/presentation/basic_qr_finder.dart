import 'dart:math';

import 'package:flutter/material.dart';

/// [BasicQRFinder] : basic design for QR scanner.
/// [apertureEdge] : margin of [CameraPreview] to the screen.
/// [viewFinderEdge] : center of camera let the users places to the QR code picture, it is the length of white border lines.
/// [child] : is front of this, and inside the  finder rectangle.
class BasicQRFinder extends StatelessWidget {
  final double apertureEdge;
  final double viewFinderEdge;
  final Widget? child;

  const BasicQRFinder({
    super.key,
    this.apertureEdge = 32.0,
    this.viewFinderEdge = 48.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.white;
    final qrFinderRectDimension = MediaQuery.of(context).size.shortestSide - apertureEdge * 2;
    final x = max(0.0, qrFinderRectDimension - viewFinderEdge);
    return Stack(
      fit: StackFit.expand,
      children: [
        // background
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut),
              ),
              // add a mask for qr finder rectangle.
              Align(
                child: Container(
                  width: qrFinderRectDimension,
                  height: qrFinderRectDimension,
                  padding: EdgeInsets.all(apertureEdge),
                  color: borderColor, // any color.
                ),
              ),
            ],
          ),
        ),
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
        if (child != null) child!,
      ],
    );
  }
}
