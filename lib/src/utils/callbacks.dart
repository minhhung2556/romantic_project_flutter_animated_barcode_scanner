import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../index.dart';

typedef OnBarcodesFoundCallback = void Function(List<BarcodeX> barcodes);
typedef OnFailedToDoSomething = void Function(Object? e, StackTrace? s);
typedef OnCameraIsReady = void Function(CameraController controller);
typedef OnCameraIsStreaming = void Function(CameraImage image);
typedef BarcodesWidgetBuilder = Widget Function(BuildContext context, List<BarcodeX> barcodes);
