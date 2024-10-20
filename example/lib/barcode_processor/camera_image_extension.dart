import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image/image.dart' as imglib;

extension CameraImageX on CameraImage {
  Uint8List getNv21Uint8List() {
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

  Uint8List? get _imageBytes {
    final allBytes = WriteBuffer();
    try {
      for (final plane in planes) {
        allBytes.putUint8List(plane.bytes);
      }
      var imageBytes = allBytes.done().buffer.asUint8List();
      return imageBytes;
    } catch (e) {
      debugPrint('CameraImageX.bytes.error: $e');
    }
    return null;
  }

  Uint8List? get bytes {
    if (Platform.isAndroid && InputImageFormat.yuv420 == inputImageFormat) {
      return getNv21Uint8List().compressImage();
    } else {
      return _imageBytes?.compressImage();
    }
  }

  InputImageFormat get inputImageFormat {
    switch (format.group) {
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.nv21;
    }
  }
}

extension ImageBytesX on Uint8List {
  Uint8List compressImage([int quality = 50]) {
    try {
      final image = imglib.decodeImage(this);
      if (image == null) {
        debugPrint('CameraImageX.compressImage.error: failed to decodeImage');
        return this;
      } else {
        return Uint8List.fromList(imglib.encodeJpg(image, quality: quality));
      }
    } catch (e) {
      debugPrint('CameraImageX.compressImage.error: $e');
      return this;
    }
  }
}
