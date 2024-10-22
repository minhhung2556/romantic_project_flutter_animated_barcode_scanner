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

  Future<List<CameraDescription>?> _initializeCamera() async {
    debugPrint('_ScannerPreviewState._initializeCamera');
    try {
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
    return Stack(
      fit: StackFit.expand,
      children: [
        OrientationBuilder(
          builder: (context, orientation) {
            return FutureBuilder(
                key: GlobalKey(), // init camera whenever orientation changed.
                future: _initializeCamera(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final size =_controller.value.previewSize!;
                    return Container(
                      alignment: Alignment.center,
                      width: size.width,
                      height: size.height,
                      child: CameraPreview(
                        _controller,
                        child: _buildBarcodes(context),
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                });
          },
        ),
        BasicQRFinder(),
      ],
    );
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
                    cornerPoints: barcode.barcode.cornerPoints.map((e) => Offset(e.x.toDouble(), e.y.toDouble())).toList(growable: false),
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
}
