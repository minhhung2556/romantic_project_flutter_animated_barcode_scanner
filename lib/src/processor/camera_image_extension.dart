import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Some extension methods when handling [CameraImage].
extension CameraImageX on CameraImage {
  /// Converts the [CameraImage] to a `Uint8List` in NV21 format.
  ///
  /// On Android, the camera image is typically in YUV_420_888 or some cases in BGRA_8888 format, which
  /// can be represented as NV21. This method combines the Y, U, and V planes
  /// into a single byte array with YYYYVU packaging. This is useful for
  ///  image processing libraries that expect this format.
  Uint8List get getNv21ImageBytes {
    final width = this.width;
    final height = this.height;

    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = (width * height * 1.5).toInt();
    final nv21 = List<int>.filled(numPixels, 0);

    // Full size Y channel and quarter size U+V channels.
    var idY = 0;
    var idUV = width * height;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    // Copy Y & UV channel.
    // NV21 format is expected to have YYYYVU packaging.
    // The U/V planes are guaranteed to have the same row stride and pixel stride.
    // getRowStride analogue??
    final uvRowStride = uPlane.bytesPerRow;
    // getPixelStride analogue
    final uvPixelStride = uPlane.bytesPerPixel ?? 0;
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 0;

    for (var y = 0; y < height; ++y) {
      final uvOffset = y * uvRowStride;
      final yOffset = y * yRowStride;

      for (var x = 0; x < width; ++x) {
        nv21[idY++] = yBuffer[yOffset + x * yPixelStride];

        if (y < uvHeight && x < uvWidth) {
          final bufferIndex = uvOffset + (x * uvPixelStride);
          //V channel
          nv21[idUV++] = vBuffer[bufferIndex];
          //V channel
          nv21[idUV++] = uBuffer[bufferIndex];
        }
      }
    }
    return Uint8List.fromList(nv21);
  }

  /// Concatenates the bytes of all planes in the [CameraImage] into a single `Uint8List`.
  ///
  /// This is a straightforward concatenation and might not represent a standard
  /// image format. It's useful for debugging or when a raw byte stream is needed.
  Uint8List get getOriginalImageBytes {
    final allBytes = WriteBuffer();
    try {
      for (final plane in planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final imageBytes = allBytes.done().buffer.asUint8List();
      return imageBytes;
    } catch (e) {
      debugPrint('CameraImageX.bytes.error: $e');
    }
    return Uint8List(0);
  }

  /// Get image [Size].
  Size get size => Size(width.toDouble(), height.toDouble());
}
