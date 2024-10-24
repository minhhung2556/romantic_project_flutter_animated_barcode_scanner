import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeX {
  /// [barcode] : that found when process the [CameraImage].
  final Barcode barcode;
  /// [imageSize] : that fits with device orientation and camera sensor orientation.
  final Size imageSize;

  BarcodeX({
    required this.barcode,
    required this.imageSize,
  });
}