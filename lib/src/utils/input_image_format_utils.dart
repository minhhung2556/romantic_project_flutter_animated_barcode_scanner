import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// A class that provides utility functions for converting between different
/// image format enums from the `camera` and `google_mlkit_commons` packages.

/// Extension to convert an [InputImageFormat] to an [ImageFormatGroup].
extension CameraInputImageFormatConverter on InputImageFormat {
  /// Converts an [InputImageFormat] to an [ImageFormatGroup].
  ImageFormatGroup? get toCameraInputImageFormat {
    switch (this) {
      case InputImageFormat.nv21:
        return ImageFormatGroup.nv21;
      case InputImageFormat.bgra8888:
        return ImageFormatGroup.bgra8888;
      case InputImageFormat.yuv420:
      case InputImageFormat.yuv_420_888:
        return ImageFormatGroup.yuv420;
      default:
        return null; // will use default settings.
    }
  }
}

/// Extension to convert an [ImageFormatGroup] to an [InputImageFormat].
extension MLKitInputImageFormatConverter on ImageFormatGroup {
  /// Converts an [ImageFormatGroup] to an [InputImageFormat].
  InputImageFormat get toMLKitInputImageFormat {
    switch (this) {
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.nv21:
      default:
        return InputImageFormat.nv21;
    }
  }
}

/// Extension to convert a [String] to an [ImageFormatGroup].
extension ImageFormatGroupFromString on String {
  /// Converts a [String] to an [ImageFormatGroup].
  ImageFormatGroup get toCameraInputImageFormat {
    switch (this) {
      case 'bgra8888':
        return ImageFormatGroup.bgra8888;
      case 'yuv420':
        return ImageFormatGroup.yuv420;
      case 'nv21':
        return ImageFormatGroup.nv21;
      case 'jpeg':
        return ImageFormatGroup.jpeg;
      default:
        return ImageFormatGroup.unknown;
    }
  }
}
