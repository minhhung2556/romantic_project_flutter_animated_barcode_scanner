import 'package:flutter/material.dart';

import '../index.dart';

/// Determines how the [BarcodeScannerPreview] is displayed within the [BarcodeScannerPreviewWrapper].
enum BarcodeScannerPreviewMode { fullscreen, fitToPicture, square }

/// The main widget of this package. This is a ready-to-use widget to show a barcode scanner.
///
/// This widget wraps the [BarcodeScannerPreview] and provides different layout modes.
///
/// Use [mode] to specify the layout mode. See [BarcodeScannerPreviewMode] for options:
/// - [BarcodeScannerPreviewMode.square] (default): A square view finder.
/// - [BarcodeScannerPreviewMode.fullscreen]: A full-screen view finder.
/// - [BarcodeScannerPreviewMode.fitToPicture]: The view finder fits the camera's picture size.
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
  Size previewSize = Size.zero;

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
        'BarcodeScannerPreviewWrapper.build: previewSize=$previewSize',
      );

      if (widget.mode == BarcodeScannerPreviewMode.fitToPicture) {
        return SizedBox.fromSize(
          size: previewSize,
          child: Stack(
            children: [
              widget.barcodeScannerPreview,
              if (widget.finderWidget != null)
                Center(child: widget.finderWidget),
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
          'BarcodeScannerPreviewWrapper.build: screenVerticalPadding=$screenVerticalPadding, screenSize=$screenSize, scale=$scale',
        );
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
                Center(child: widget.finderWidget),
            ],
          ),
        );
      }
    }
    // default.
    final dimension = context.findRenderObject()?.paintBounds.shortestSide ??
        MediaQuery.of(context).size.shortestSide;
    return SizedBox.square(
      dimension: dimension,
      child: Stack(
        children: [
          SizedBox.square(
            dimension: dimension,
            child: ClipRect(
              child: Stack(
                children: [
                  widget.barcodeScannerPreview,
                  if (widget.finderWidget != null) Center(child: widget.finderWidget),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
