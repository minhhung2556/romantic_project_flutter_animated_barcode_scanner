import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../index.dart';

typedef OnFailedToDoSomething = void Function(Object? e, StackTrace? s);

typedef OnBarcodesFound = void Function(List<BarcodeX> barcodes);
typedef OnCameraIsReady = void Function(CameraController controller);
typedef OnCameraIsStreaming = void Function(CameraImage image);
typedef OnFailedToProcessBarcode = void Function(dynamic image, Object? e, StackTrace? s);

typedef BarcodesWidgetBuilder = Widget Function(BuildContext context, List<BarcodeX> barcodes);
typedef CameraControllerBuilder = Future<CameraController> Function();
