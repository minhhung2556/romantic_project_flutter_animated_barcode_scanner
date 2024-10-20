import 'dart:ui';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeX {
  final Barcode barcode;
  final InputImage image;

  BarcodeX({required this.barcode, required this.image});

  /// imageSize that fit with camera orientation.
  Size get imageSize => (image.metadata!.rotation == InputImageRotation.rotation90deg ||
          image.metadata!.rotation == InputImageRotation.rotation270deg)
      ? Size(image.metadata!.size.height, image.metadata!.size.width)
      : image.metadata!.size;
}
