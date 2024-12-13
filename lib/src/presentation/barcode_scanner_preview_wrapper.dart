import 'package:flutter/material.dart';

import '../index.dart';

/// Mode to show the [BarcodeScannerPreview].
/// [fullscreen] : fit to the full screen size of the device.
/// [fitToPicture] : fit to the picture/image size of the camera.
/// [square] : square with dimension is the screen shortest side (screen width in portrait mode).
enum BarcodeScannerPreviewMode { fullscreen, fitToPicture, square }

/// The main widget of this package. This is a ready-to-use widget to show a barcode scanner.
/// [mode] : See [BarcodeScannerPreview].
/// [barcodeScannerPreview] : See [BarcodeScannerPreview].
/// [finderWidget] : the barcode finder widget. See [AnimatedBarcodeFinder].
class BarcodeScannerPreviewWrapper extends StatefulWidget {
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
  State<BarcodeScannerPreviewWrapper> createState() =>
      _BarcodeScannerPreviewWrapperState();
}

class _BarcodeScannerPreviewWrapperState
    extends State<BarcodeScannerPreviewWrapper> {
  var previewSize = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.barcodeScannerPreview.cameraPreviewSizeNotifier.addListener(() {
      setState(() {
        previewSize =
            widget.barcodeScannerPreview.cameraPreviewSizeNotifier.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (previewSize != Size.zero) {
      debugPrint(
          'BarcodeScannerPreviewWrapper.build: previewSize=$previewSize');

      if (widget.mode == BarcodeScannerPreviewMode.fitToPicture) {
        return SizedBox.fromSize(
          size: previewSize,
          child: Stack(
            children: [
              widget.barcodeScannerPreview,
              if (widget.finderWidget != null)
                Center(child: widget.finderWidget!),
            ],
          ),
        );
      } else if (widget.mode == BarcodeScannerPreviewMode.fullscreen) {
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
                    child: widget.barcodeScannerPreview,
                  ),
                ),
              ),
              if (widget.finderWidget != null)
                Center(child: widget.finderWidget!),
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
          widget.barcodeScannerPreview,
          if (widget.finderWidget != null) Center(child: widget.finderWidget!),
        ],
      ),
    );
  }
}
