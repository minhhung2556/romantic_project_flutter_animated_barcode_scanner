import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../index.dart';

enum BarcodeScannerPreviewMode { fullscreen, fitToPicture, square }

class BarcodeScannerPreviewWrapper extends StatelessWidget {
  final BarcodeScannerPreviewMode mode;
  final BarcodeScannerPreview barcodeScannerPreview;
  final CameraController? cameraController;
  final Widget? finderWidget;

  const BarcodeScannerPreviewWrapper({
    super.key,
    this.mode = BarcodeScannerPreviewMode.square,
    required this.barcodeScannerPreview,
    this.cameraController,
    this.finderWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (cameraController?.value.isInitialized == true &&
        cameraController?.value.previewSize != null) {
      if (mode == BarcodeScannerPreviewMode.fitToPicture) {
        return SizedBox.fromSize(
          size: cameraController!.value.previewSize!,
          child: Stack(
            children: [
              barcodeScannerPreview,
              if (finderWidget != null) Center(child: finderWidget!),
            ],
          ),
        );
      } else if (mode == BarcodeScannerPreviewMode.fullscreen) {
        // fullscreen.
        final screenSize = MediaQuery.of(context).size;
        return SizedBox.fromSize(
          size: screenSize,
          child: Stack(
            children: [
              SizedBox.fromSize(
                //size for ClipRect.
                size: screenSize,
                child: ClipRect(
                  child: Transform.scale(
                    alignment: Alignment.topCenter,
                    scale: cameraController!.value.previewSize!.longestSide /
                        screenSize.longestSide,
                    child: barcodeScannerPreview,
                  ),
                ),
              ),
              if (finderWidget != null) Center(child: finderWidget!),
            ],
          ),
        );
      }
    }
    // default.
    final screenSize = MediaQuery.of(context).size;
    return SizedBox.square(
      dimension: screenSize.shortestSide,
      child: Stack(
        children: [
          barcodeScannerPreview,
          if (finderWidget != null) Center(child: finderWidget!),
        ],
      ),
    );
  }
}
