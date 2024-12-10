import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

class BarcodeScannerPreview extends StatefulWidget {
  final OnBarcodesFoundCallback? onBarcodesFound;
  final OnFailedToDoSomething? onFailedToProcessBarcode;
  final List<DeviceOrientation> originalPreferredOrientations;

  const BarcodeScannerPreview(
      {super.key, this.onBarcodesFound, this.onFailedToProcessBarcode, required this.originalPreferredOrientations});

  @override
  State<BarcodeScannerPreview> createState() => _BarcodeScannerPreviewState();
}

class _BarcodeScannerPreviewState extends State<BarcodeScannerPreview> {
  BarcodeProcessor? barcodeProcessor;
  CameraController? cameraController;
  List<BarcodeX> barcodes = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreviewWrapper(
          originalPreferredOrientations: widget.originalPreferredOrientations,
          onCameraIsReady: onCameraIsReady,
          onCameraIsStreaming: onCameraIsStreaming,
          child: _buildBarcodes(context, barcodes),
        ),
        RomanticQRFinder(),
      ],
    );
  }

  void onCameraIsReady(CameraController controller, Size pictureSize, Size previewSize) {
    this.cameraController = controller;
    _initBarcodeProcessor();
  }

  void onCameraIsStreaming(CameraImage image) {
    if (barcodeProcessor != null) {
      barcodeProcessor!.processImage(image);
    }
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

  Widget _buildBarcodes(BuildContext context, List<BarcodeX> barcodes) {
    return Stack(
      children: [
        ...barcodes.map((barcode) {
          return BarcodeRectangle(
            cornerPoints: barcode.cornerPoints,
            imageSize: barcode.imageSize,
            color: Colors.white,
            strokeWidth: 2,
          );
        }),
      ],
    );
  }
}
