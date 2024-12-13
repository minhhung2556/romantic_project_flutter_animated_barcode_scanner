import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Data model for a barcode.
class BarcodeX {
  /// [barcode] : that found when process the [CameraImage].
  final Barcode barcode;
  /// [imageSize] : that fits with device orientation and camera sensor orientation.
  final Size imageSize;

  /// Constructor.
  BarcodeX({
    required this.barcode,
    required this.imageSize,
  });

  @override
  String toString() {
    return '[${DateTime.now}]BarcodeX(rawValue=${barcode.rawValue},imageSize=$imageSize)';
  }

  /// List of [Barcode] corner points in [Offset].
  List<Offset> get cornerPoints =>
      barcode.cornerPoints.map((e) => Offset(e.x.toDouble(), e.y.toDouble())).toList(growable: false);
}