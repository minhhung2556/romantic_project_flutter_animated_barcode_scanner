import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.black,
                    child: SizedBox.square(
                      dimension: screenSize.shortestSide,
                      child: Center(child: CameraPreview(_controller)),
                    ),
                  ),
                  BasicQRFinder(),
                  // _buildBarcodes(context),
                ],
              );
            } else {
              return SizedBox.shrink();
            }
          });
    });
  }

  Widget _buildBarcodes(BuildContext context) {
    return StreamBuilder<List<BarcodeX>>(
        stream: barcodeProcessor.latestBarcodes.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Stack(
              children: [
                ...snapshot.data!.map((barcode) {
                  final originalImageSize = barcode.imageSize;
                  final originalCornerPoints = barcode.barcode.cornerPoints
                      .map((e) => Offset(e.x.toDouble(), e.y.toDouble()))
                      .toList(growable: false);
                  late Size adaptedImageSize;
                  if (_controller.value.deviceOrientation == DeviceOrientation.landscapeLeft ||
                      _controller.value.deviceOrientation == DeviceOrientation.landscapeRight) {
                    adaptedImageSize = Size(originalImageSize.height, originalImageSize.width);
                  } else {
                    adaptedImageSize = originalImageSize;
                  }
                  return BarcodeRectangle(
                    cornerPoints: originalCornerPoints,
                    imageSize: adaptedImageSize,
                  );
                }),
              ],
            );
          } else {
            return SizedBox.shrink();
          }
        });
  }
}
