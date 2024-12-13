import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

/// Handles processing barcodes effectively.
/// [cameraController] : is used to get some required information to process an image.
/// [onBarcodesFound] : callback when some [BarcodeX] are found.
/// [onFailedToProcessBarcode] : callback when an error occurs.
class BarcodeProcessor {
  Future<List<BarcodeX>>? _processing;
  CameraImage? _processingImage;
  late BarcodeScanner barcodeScanner;
  final CameraController cameraController;
  final OnBarcodesFound onBarcodesFound;
  final OnFailedToProcessBarcode? onFailedToProcessBarcode;

  /// Constructor.
  BarcodeProcessor({
    List<BarcodeFormat>? barcodeFormats,
    required this.cameraController,
    required this.onBarcodesFound,
    this.onFailedToProcessBarcode,
  }) {
    barcodeScanner = barcodeFormats == null
        ? BarcodeScanner()
        : BarcodeScanner(formats: barcodeFormats);
  }

  bool get _shouldProcess => _processingImage == null && _processing == null;

  /// Some [barcodes] were found.
  void _onProcessingCompleted(List<BarcodeX> barcodes) {
    onBarcodesFound(barcodes);
    _processingImage = null;
    _processing = null;
  }

  /// Releases all resources.
  Future<void> dispose() async {
    await barcodeScanner.close();
    _processingImage = null;
    _processing = null;
  }

  /// Add an [image] to queue to process.
  void processImage(CameraImage image) {
    if (_shouldProcess) {
      _processing = _processImage(_processingImage = image)
        ..then(_onProcessingCompleted);
    }
  }

  /// Start processing an [image].
  Future<List<BarcodeX>> _processImage(CameraImage image) async {
    try {
      // debugPrint('BarcodeProcessor._processImage: imageSize=${image.size}');
      final inputImage = InputImage.fromBytes(
        bytes: image.imageBytes!,
        metadata: InputImageMetadata(
          size: image.size,
          rotation: InputImageRotationValue.fromRawValue(
                  cameraController.description.sensorOrientation) ??
              InputImageRotation.rotation0deg,
          format: image.inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
      return await _processImageForBarcode(inputImage);
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s, label: 'BarcodeProcessor._processImage.error: $e');
      onFailedToProcessBarcode?.call(image, e, s);
    }
    return [];
  }

  /// Process an [image] to find barcodes.
  Future<List<BarcodeX>> _processImageForBarcode(InputImage image) async {
    try {
      final res = await barcodeScanner.processImage(image);
      await barcodeScanner.close();
      if (res.isNotEmpty) {
        final imageSize = image.metadata!.size;
        debugPrint(
            'BarcodeProcessor._processImageForBarcode.found: ${res.length} barcodes, imageSize=$imageSize');
        late Size adaptedImageSize;
        // device is forced to portrait mode.
        if (imageSize.width > imageSize.height) {
          // image is landscape.
          adaptedImageSize = Size(imageSize.height, imageSize.width);
        } else {
          adaptedImageSize = imageSize;
        }
        return res
            .map((e) => BarcodeX(barcode: e, imageSize: adaptedImageSize))
            .toList(growable: false);
      }
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s,
          label: 'BarcodeProcessor._processImageForBarcode.error: $e');
      onFailedToProcessBarcode?.call(image, e, s);
    }
    return List.empty();
  }
}
