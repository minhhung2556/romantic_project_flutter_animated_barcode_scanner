import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

class BarcodeScannerPreview extends StatefulWidget {
  final OnCameraIsReady? onCameraIsReady;
  final OnCameraIsStreaming? onCameraIsStreaming;
  final OnBarcodesFoundCallback? onBarcodesFound;
  final OnFailedToDoSomething? onFailedToProcessBarcode;

  final List<DeviceOrientation> originalPreferredOrientations;

  final BarcodesWidgetBuilder? barcodesBuilder;
  final CameraControllerBuilder cameraControllerBuilder;

  const BarcodeScannerPreview({
    super.key,
    required this.cameraControllerBuilder,
    this.onCameraIsReady,
    this.onCameraIsStreaming,
    this.onBarcodesFound,
    this.onFailedToProcessBarcode,
    required this.originalPreferredOrientations,
    this.barcodesBuilder,
  });

  @override
  State<BarcodeScannerPreview> createState() => _BarcodeScannerPreviewState();
}

class _BarcodeScannerPreviewState extends State<BarcodeScannerPreview> {
  BarcodeProcessor? barcodeProcessor;
  CameraController? cameraController;
  List<BarcodeX> barcodes = [];

  @override
  Widget build(BuildContext context) {
    return CameraPreviewWrapper(
      cameraControllerBuilder: widget.cameraControllerBuilder,
      originalPreferredOrientations: widget.originalPreferredOrientations,
      onCameraIsReady: onCameraIsReady,
      onCameraIsStreaming: onCameraIsStreaming,
      child: widget.barcodesBuilder != null
          ? widget.barcodesBuilder!(context, barcodes)
          : null,
    );
  }

  void onCameraIsReady(CameraController controller) {
    this.cameraController = controller;
    _initBarcodeProcessor();
    widget.onCameraIsReady?.call(controller);
  }

  void onCameraIsStreaming(CameraImage image) {
    if (barcodeProcessor != null) {
      barcodeProcessor!.processImage(image);
    }
    widget.onCameraIsStreaming?.call(image);
  }

  void onBarcodesFound(List<BarcodeX> barcodes) {
    if (mounted) {
      setState(() {
        this.barcodes = barcodes;
        widget.onBarcodesFound?.call(barcodes);
      });
    }
  }

  void _initBarcodeProcessor() async {
    barcodeProcessor = BarcodeProcessor(
      cameraController: cameraController!,
      onBarcodesFound: onBarcodesFound,
      barcodeFormats: [BarcodeFormat.qrCode],
      onFailedToProcessBarcode: widget.onFailedToProcessBarcode,
    );
  }
}
