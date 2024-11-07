import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

class BarcodeProcessor {
  late BarcodeScanner barcodeScanner;

  Future<List<BarcodeX>>? _processing;
  CameraImage? _processingImage;
  final CameraController cameraController;

  final OnBarcodesFoundCallback onBarcodesFound;
  final OnFailedToDoSomething? onFailedToProcessBarcode;

  BarcodeProcessor({
    List<BarcodeFormat>? barcodeFormats,
    required this.cameraController,
    required this.onBarcodesFound,
    this.onFailedToProcessBarcode,
  }) {
    barcodeScanner = barcodeFormats == null ? BarcodeScanner() : BarcodeScanner(formats: barcodeFormats);
  }

  bool get _shouldProcess => _processingImage == null && _processing == null;

  void onProcessingCompleted(List<BarcodeX> barcodes) {
    onBarcodesFound(barcodes);
    _processingImage = null;
    _processing = null;
  }

  Future<void> dispose() async {
    await barcodeScanner.close();
    _processingImage = null;
    _processing = null;
  }

  void processImage(CameraImage image) {
    if (_shouldProcess) {
      _processing = _processImage(_processingImage = image)..then(onProcessingCompleted);
    }
  }

  Future<List<BarcodeX>> _processImage(CameraImage image) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: image.imageBytes!,
        metadata: InputImageMetadata(
          size: image.size,
          rotation: InputImageRotationValue.fromRawValue(cameraController.description.sensorOrientation) ??
              InputImageRotation.rotation0deg,
          format: image.inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
      return await _processImageForBarcode(inputImage);
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'BarcodeProcessor._processImage.error: $e');
      onFailedToProcessBarcode?.call(e, s);
    }
    return [];
  }

  Future<List<BarcodeX>> _processImageForBarcode(InputImage image) async {
    try {
      final res = await barcodeScanner.processImage(image);
      await barcodeScanner.close();
      debugPrint('BarcodeProcessor._processImageForBarcode.found: ${res.length} barcodes.');
      if (res.isNotEmpty) {
        late Size adaptedImageSize;
        final deviceOrientation = cameraController.value.deviceOrientation;
        final imageSize = image.metadata!.size;
        if (deviceOrientation == DeviceOrientation.portraitUp || deviceOrientation == DeviceOrientation.portraitDown) {
          adaptedImageSize = Size(imageSize.height, imageSize.width);
        } else {
          adaptedImageSize = imageSize;
        }
        return res.map((e) => BarcodeX(barcode: e, imageSize: adaptedImageSize)).toList(growable: false);
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'BarcodeProcessor._processImageForBarcode.error: $e');
      onFailedToProcessBarcode?.call(e, s);
    }
    return List.empty();
  }
}
