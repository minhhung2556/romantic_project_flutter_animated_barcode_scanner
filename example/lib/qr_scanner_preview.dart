import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_qr_scanner/flutter_animated_qr_scanner.dart';

import 'barcode_processor/index.dart';

/// [ScannerPreview] Preview widget for QR Scanner.
class ScannerPreview extends StatefulWidget {
  const ScannerPreview({super.key});

  @override
  State<ScannerPreview> createState() => _ScannerPreviewState();
}

class _ScannerPreviewState extends State<ScannerPreview> with RouteAware {
  late CameraController _controller;
  late BarcodeProcessor barcodeProcessor;

  Future<List<CameraDescription>?> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      _controller = cameraController;
      await _controller.initialize();
      barcodeProcessor = BarcodeProcessor(cameraDescription: cameras.first);
      _controller.startImageStream((image) {
        barcodeProcessor.processImage(image);
      });
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
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initializeCamera(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildCamera(context);
          } else {
            return SizedBox.shrink();
          }
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
                  return BarcodeRectangle(
                    cornerPoints: barcode.barcode.cornerPoints,
                    boundingBox: barcode.barcode.boundingBox,
                    imageSize: barcode.imageSize,
                  );
                }),
              ],
            );
          } else {
            return SizedBox.shrink();
          }
        });
  }

  Widget _buildCamera(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceOrientation = _controller.value.deviceOrientation;
        final originalPreviewSize = _controller.value.previewSize!;
        debugPrint(
            '_ScannerPreviewState._buildBarcodes: deviceOrientation=$deviceOrientation, originalPreviewSize=$originalPreviewSize');
        late double rotationAngle;
        switch (deviceOrientation) {
          case DeviceOrientation.portraitDown:
            rotationAngle = 180;
            break;
          case DeviceOrientation.landscapeLeft:
            rotationAngle = -90;
            break;
          case DeviceOrientation.landscapeRight:
            rotationAngle = 90;
            break;
          case DeviceOrientation.portraitUp:
          default:
            rotationAngle = 0;
            break;
        }
        return Transform.rotate(
          angle: rotationAngle,
          child: Container(
            alignment: Alignment.center,
            width: originalPreviewSize.width,
            height: originalPreviewSize.height,
            child: CameraPreview(
              _controller,
              child: _buildBarcodes(context),
            ),
          ),
        );
      },
    );
  }
}
