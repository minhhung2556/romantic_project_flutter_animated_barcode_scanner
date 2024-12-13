import 'package:flutter/material.dart';

import '../index.dart';

enum BarcodeScannerPreviewMode { fullscreen, fitToPicture, square }

class BarcodeScannerPreviewWrapper extends StatelessWidget {
  final BarcodeScannerPreviewMode mode;
  final BarcodeScannerPreview barcodeScannerPreview;
  final Widget? finderWidget;

  const BarcodeScannerPreviewWrapper({
    super.key,
    this.mode = BarcodeScannerPreviewMode.square,
    required this.barcodeScannerPreview,
    this.finderWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: barcodeScannerPreview.cameraPreviewSizeNotifier,
      builder: (context, child) {
        final previewSize =
            barcodeScannerPreview.cameraPreviewSizeNotifier.value;
        if (previewSize != Size.zero) {
          debugPrint(
              'BarcodeScannerPreviewWrapper.build: previewSize=$previewSize');

          if (mode == BarcodeScannerPreviewMode.fitToPicture) {
            return SizedBox.fromSize(
              size: previewSize,
              child: Stack(
                children: [
                  barcodeScannerPreview,
                  if (finderWidget != null) Center(child: finderWidget!),
                ],
              ),
            );
          } else if (mode == BarcodeScannerPreviewMode.fullscreen) {
            // fullscreen.
            final screenVerticalPadding =
                (Scaffold.of(context).appBarMaxHeight ?? 0) +
                    MediaQuery.of(context).padding.vertical;
            final screenSize = MediaQuery.of(context).size;
            var scale = previewSize.longestSide /
                (screenSize.longestSide + screenVerticalPadding);
            if (scale < 1) scale = 1 / scale;
            debugPrint(
                'BarcodeScannerPreviewWrapper.build: screenVerticalPadding=$screenVerticalPadding, screenSize=$screenSize, scale=$scale');
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
                        scale: scale,
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
      },
    );
  }
}
