import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_qr_scanner/flutter_animated_qr_scanner.dart';

/// [ScannerPreview] Preview widget for QR Scanner.
class ScannerPreview extends StatefulWidget {
  const ScannerPreview({super.key});

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
        await _disposeCamera();
      }
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller.initialize();
      barcodeProcessor = BarcodeProcessor(
        cameraController: _controller,
        isDebug: true,
      );
      _controller.startImageStream((image) {
        barcodeProcessor.processImage(image);
      });
      isInitializedCamera = true;
      return cameras;
    } catch (e) {
      debugPrint('_ScannerPreviewState._initializeCamera.error: $e');
    }
    return null;
  }

  Future<void> _disposeCamera() async {
    await _controller.stopImageStream();
    await _controller.dispose();
    await barcodeProcessor.dispose();
    isInitializedCamera = false;
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return FutureBuilder(
          key: GlobalKey(), // init camera whenever orientation changed.
          future: _initializeCamera(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final screenSize = MediaQuery.sizeOf(context);

              final originalPreviewSize = _controller.value.previewSize!;
              debugPrint('_ScannerPreviewState.build: originalPreviewSize=$originalPreviewSize');
              // preview must be landscape
              final Size adaptedPreviewSize = originalPreviewSize.aspectRatio < 1
                  ? Size(originalPreviewSize.longestSide, originalPreviewSize.shortestSide)
                  : originalPreviewSize;
              debugPrint('_ScannerPreviewState.build: adaptedPreviewSize=$adaptedPreviewSize');
              debugPrint('_ScannerPreviewState.build: screenSize=$screenSize');

              return StreamBuilder<List<BarcodeX>>(
                  stream: barcodeProcessor.latestBarcodes.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData != true) {
                      return SizedBox.shrink();
                    }
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          color: Colors.black,
                          child: SizedBox.square(
                            dimension: screenSize.shortestSide,
                            child: Center(
                                child: CameraPreview(
                              _controller,
                              child: _buildBarcodes(context, snapshot.data!, Colors.green),
                            )),
                          ),
                        ),
                        BasicQRFinder(),
                      ],
                    );
                  });
            } else {
              return SizedBox.shrink();
            }
          });
    });
  }

  Widget _buildBarcodes(BuildContext context, List<BarcodeX> barcodes, Color color) {
    return Stack(
      children: [
        ...barcodes.map((barcode) {
          final originalImageSize = barcode.imageSize;
          final originalCornerPoints =
              barcode.barcode.cornerPoints.map((e) => Offset(e.x.toDouble(), e.y.toDouble())).toList(growable: false);
          return BarcodeRectangle(
            cornerPoints: originalCornerPoints,
            imageSize: originalImageSize,
            color: color,
          );
        }),
      ],
    );
  }
}
