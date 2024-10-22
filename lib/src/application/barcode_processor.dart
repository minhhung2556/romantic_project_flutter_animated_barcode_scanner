import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_qr_scanner/src/domain/index.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'index.dart';

class BarcodeProcessor {
  late BarcodeScanner barcodeScanner;

  /// latest found barcodes.
  final StreamController<List<BarcodeX>> latestBarcodes = StreamController();

  final _waitingImageQueue = List<CameraImage>.empty(growable: true);
  Future<List<BarcodeX>>? _processing;
  CameraImage? _processingImage;
  final int maxImageQueue;
  final CameraController cameraController;

  BarcodeProcessor({
    this.maxImageQueue = 1,
    List<BarcodeFormat>? barcodeFormats,
    required this.cameraController,
  }) {
    barcodeScanner = barcodeFormats == null ? BarcodeScanner() : BarcodeScanner(formats: barcodeFormats);
  }

  bool get _shouldProcess => _processingImage == null && _processing == null && _waitingImageQueue.isNotEmpty;

  void onProcessingCompleted(List<BarcodeX> barcodes) {
    latestBarcodes.add(barcodes);
    _waitingImageQueue.remove(_processingImage);
    _processingImage = null;
    _processing = null;
    continueProcess();
  }

  void continueProcess() {
    if (_shouldProcess) {
      // always process latest image.
      _processingImage = _waitingImageQueue.last;
      _processing = _processImage(_processingImage!)..then(onProcessingCompleted);
    } else {
      //waiting.
    }
  }

  Future<void> dispose() async {
    await barcodeScanner.close();
    _processingImage = null;
    _processing = null;
    _waitingImageQueue.clear();
    latestBarcodes.close();
  }

  void processImage(CameraImage image) {
    if (_waitingImageQueue.length < maxImageQueue) {
      _waitingImageQueue.add(image);
      continueProcess();
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
    }
    return [];
  }

  Future<List<BarcodeX>> _processImageForBarcode(InputImage image) async {
    try {
      final deviceOrientation = cameraController.value.deviceOrientation;
      final imageSize = image.metadata!.size;
      final res = await barcodeScanner.processImage(image);
      await barcodeScanner.close();
      if (res.isNotEmpty) {
        late Size adaptedImageSize;
        if (deviceOrientation == DeviceOrientation.portraitUp || deviceOrientation == DeviceOrientation.portraitDown) {
          adaptedImageSize = Size(imageSize.height, imageSize.width);
        } else {
          adaptedImageSize = imageSize;
        }
        return res.map((e) => BarcodeX(barcode: e, imageSize: adaptedImageSize)).toList(growable: false);
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'BarcodeProcessor._processImageForBarcode.error: $e');
    }
    return List.empty(growable: false);
  }
}
