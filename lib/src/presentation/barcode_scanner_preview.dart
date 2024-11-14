import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

class BarcodeScannerPreview extends StatefulWidget {
  final OnBarcodesFoundCallback? onBarcodesFound;
  final OnFailedToDoSomething? onFailedToProcessBarcode;

  const BarcodeScannerPreview({super.key, this.onBarcodesFound, this.onFailedToProcessBarcode});

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
    return OrientationBuilder(builder: (context, orientation) {
      return CameraPreviewWrapper(
        onCameraIsReady: onCameraIsReady,
        onCameraIsStreaming: onCameraIsStreaming,
        foreground: BasicQRFinder(),
        cameraChild: _buildBarcodes(context, barcodes),
      );
    });
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
        barcodes.forEach((e) {
          print('_BarcodeScannerPreviewState.onBarcodesFound: ${e.cornerPoints}');
        });
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final convertedBarcodes = /*isLandscape
        ? barcodes.map((e) {
            return BarcodeX(
                barcode: Barcode(
                  type: e.barcode.type,
                  format: e.barcode.format,
                  displayValue: e.barcode.displayValue,
                  rawValue: e.barcode.rawValue,
                  rawBytes: e.barcode.rawBytes,
                  boundingBox: e.barcode.boundingBox,
                  cornerPoints: e.barcode.cornerPoints.map((point) => Point(point.y, point.x)).toList(growable: false),
                  value: e.barcode.value,
                ),
                imageSize: e.imageSize);
          }).toList(growable: false)
        : */barcodes;
    return Stack(
      children: [
        ...convertedBarcodes.map((barcode) {
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
