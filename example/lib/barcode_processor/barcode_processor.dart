import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'index.dart';

class BarcodeProcessor {
  late BarcodeScanner barcodeScanner;
  final List<BarcodeFormat>? barcodeFormats;
  final CameraDescription cameraDescription;
  final imageQueue = List<CameraImage>.empty(growable: true);
  Future<List<BarcodeX>>? processing;
  CameraImage? processingImage;

  /// latest found barcodes.
  final StreamController<List<BarcodeX>> latestBarcodes = StreamController();
  final int maxImageQueue;

  BarcodeProcessor({
    this.barcodeFormats,
    required this.cameraDescription,
    this.maxImageQueue = 5,
  }) {
    barcodeScanner = barcodeFormats == null ? BarcodeScanner() : BarcodeScanner(formats: barcodeFormats!);
  }

  bool get shouldProcess => processingImage == null && processing == null && imageQueue.isNotEmpty;

  void onProcessingCompleted(List<BarcodeX> barcodes) {
    latestBarcodes.add(barcodes);
    imageQueue.remove(processingImage);
    processingImage = null;
    processing = null;
    continueProcess();
  }

  void continueProcess() {
    if (shouldProcess) {
      // always process latest image.
      processingImage = imageQueue.last;
      processing = _processImage(processingImage!)..then(onProcessingCompleted);
    } else {
      //waiting.
    }
  }

  Future<void> dispose() async {
    await barcodeScanner.close();
    processingImage = null;
    processing = null;
    imageQueue.clear();
    latestBarcodes.close();
  }

  void processImage(CameraImage image) {
    if (imageQueue.length < maxImageQueue) {
      imageQueue.add(image);
      continueProcess();
    }
  }

  Future<List<BarcodeX>> _processImage(CameraImage image) async {
    debugPrint('BarcodeProcessor._processImage: ${DateTime.now()}');
    debugPrint('BarcodeProcessor._processImage: imageQueue.length=${imageQueue.length}');
    try {
      var inputImageFormat = image.inputImageFormat;
      final Uint8List? imageBytes = image.bytes;
      if (imageBytes != null) {
        final inputImage = InputImage.fromBytes(
          bytes: imageBytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotationValue.fromRawValue(cameraDescription.sensorOrientation) ?? InputImageRotation.rotation0deg,
            format: inputImageFormat,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
        return await _processImageForBarcode(inputImage);
      }else{
        debugPrint('BarcodeProcessor._processImage: imageBytes is failed to parse.');
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: 'BarcodeProcessor._processImage.error: $e');
    }
    return [];
  }

  Future<List<BarcodeX>> _processImageForBarcode(InputImage image) async {
    debugPrint('BarcodeProcessor._processImageForBarcode: ${DateTime.now()}');
    final res = await barcodeScanner.processImage(image);

    if (res.isNotEmpty) {
      return res.map((e) {
        debugPrint(
            'BarcodeProcessor._processImageForBarcode.image: rotation=${image.metadata!.rotation}, imageSize=${image.metadata!.size}');
        debugPrint('BarcodeProcessor._processImageForBarcode.barcode: boundingBox=${e.boundingBox}');
        return BarcodeX(barcode: e, image: image);
      }).toList(growable: false);
    }
    barcodeScanner.close();
    return List.empty(growable: false);
  }
}
