import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../index.dart';

/// When any error occurs.
/// [e] : error object.
/// [s] : stack trace of this error.
typedef OnFailedToDoSomething = void Function(Object? e, StackTrace? s);

/// Callback when some barcodes are found.
/// [barcodes] : list of found barcodes.
typedef OnBarcodesFound = void Function(List<BarcodeX> barcodes);

/// Callback when the camera is initialized.
/// [controller] : the [CameraController] is ready to use.
typedef OnCameraIsReady = void Function(CameraController controller);

/// Callback when the camera is streaming images.
/// [image] : raw image (frame) from the camera.
typedef OnCameraIsStreaming = void Function(CameraImage image);

/// When any error occurs.
/// [image] :
/// - is [CameraImage] when the [CameraImage] was failed to convert.
/// - is [InputImage] when the [BarcodeScanner] was failed to process an [InputImage].
/// [e] : error object.
/// [s] : stack trace of this error.
typedef OnFailedToProcessBarcode = void Function(
  dynamic image,
  Object? e,
  StackTrace? s,
);

/// Build barcode rectangles.
/// [context] : [BuildContext] of parent widget.
/// [barcodes] : list of found barcodes.
typedef BarcodesWidgetBuilder = Widget Function(
  BuildContext context,
  List<BarcodeX> barcodes,
);

/// Function to build a [CameraController].
typedef CameraControllerBuilder = Future<CameraController> Function();
