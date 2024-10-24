import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

/// [ScannerPreview] Preview widget for Barcode Scanner.
class ScannerPreview extends StatefulWidget {
  final OnBarcodesFoundCallback onBarcodesFound;
  final Widget? foreground;
  final OnFailedToDoSomething? onFailedToProcessBarcode;
  final OnFailedToDoSomething? onFailedToInitializeCamera;
  final OnFailedToDoSomething? onFailedToDisposeCamera;

  const ScannerPreview({
    super.key,
    required this.onBarcodesFound,
    this.foreground,
    this.onFailedToInitializeCamera,
    this.onFailedToDisposeCamera,
    this.onFailedToProcessBarcode,
  });

  @override
  State<ScannerPreview> createState() => _ScannerPreviewState();
}

class _ScannerPreviewState extends State<ScannerPreview> with RouteAware {
  late CameraController _controller;
  late BarcodeProcessor barcodeProcessor;
  bool isInitializedCamera = false;

  Future<List<CameraDescription>?> _initializeCamera() async {
    debugPrint('_ScannerPreviewState._initializeCamera');
    try {
      if (isInitializedCamera) {
        _disposeCamera();
      }
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller.initialize();
      barcodeProcessor = BarcodeProcessor(
        cameraController: _controller,
        onBarcodesFound: (barcodes) {
          if (mounted) {
            widget.onBarcodesFound(barcodes);
          }
        },
        barcodeFormats: [BarcodeFormat.qrCode],
        onFailedToProcessBarcode: widget.onFailedToProcessBarcode,
      );
      await _controller.startImageStream(onImageStream);
      isInitializedCamera = true;
      return cameras;
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: '_ScannerPreviewState._initializeCamera.error: $e');
      widget.onFailedToInitializeCamera?.call(e, s);
    }
    return null;
  }

  Future<void> onImageStream(CameraImage image) async {
    barcodeProcessor.processImage(image);
  }

  void _disposeCamera() {
    try {
      unawaited(_controller.stopImageStream());
      unawaited(_controller.dispose());
      unawaited(barcodeProcessor.dispose());
      isInitializedCamera = false;
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: '_ScannerPreviewState._disposeCamera.error: $e');
      widget.onFailedToDisposeCamera?.call(e, s);
    }
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return FutureBuilder(
          key: GlobalKey(), // init camera whenever orientation changed.
          future: _initializeCamera(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final screenSize = MediaQuery.sizeOf(context);

              final originalPreviewSize = _controller.value.previewSize!;
              debugPrint('_ScannerPreviewState.build: originalPreviewSize=$originalPreviewSize');
              // preview must be landscape
              final adaptedPreviewSize = originalPreviewSize.aspectRatio < 1
                  ? Size(originalPreviewSize.longestSide, originalPreviewSize.shortestSide)
                  : originalPreviewSize;
              debugPrint('_ScannerPreviewState.build: adaptedPreviewSize=$adaptedPreviewSize');
              debugPrint('_ScannerPreviewState.build: screenSize=$screenSize');

              return StreamBuilder<List<BarcodeX>>(
                stream: barcodeProcessor.latestBarcodes.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData != true) {
                    return const SizedBox.shrink();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return Stack(
                        children: [
                          SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: Transform.scale(
                              scale: (size.aspectRatio * _controller.value.aspectRatio) < 1
                                  ? 1 / (size.aspectRatio * _controller.value.aspectRatio)
                                  : size.aspectRatio * _controller.value.aspectRatio,
                              alignment: FractionalOffset.center,
                              child: Center(
                                child: CameraPreview(
                                  _controller,
                                  // Barcode cornerPoints is related to image size which is in [CameraPreview] boundaries, so they must be placed in child of [CameraPreview].
                                  child: _buildBarcodes(context, snapshot.data!),
                                ),
                              ),
                            ),
                          ),
                          if (widget.foreground != null) widget.foreground!,
                        ],
                      );
                    },
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }

  Widget _buildBarcodes(BuildContext context, List<BarcodeX> barcodes) {
    return Stack(
      children: [
        ...barcodes.map((barcode) {
          final originalImageSize = barcode.imageSize;
          final originalCornerPoints =
              barcode.barcode.cornerPoints.map((e) => Offset(e.x.toDouble(), e.y.toDouble())).toList(growable: false);

          return BarcodeRectangle(
            cornerPoints: originalCornerPoints,
            imageSize: originalImageSize,
            color: Colors.white,
            strokeWidth: 2,
          );
        }),
      ],
    );
  }
}
