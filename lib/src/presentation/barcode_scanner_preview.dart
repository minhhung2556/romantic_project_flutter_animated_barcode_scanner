import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

/// NOTE:
/// - If the image quality is medium then on android the [BarcodeScanner] can not recognize any qr codes.
/// BarcodeScannerPreview helps in handling the barcode scanner widget:
/// - Draw the [CameraPreview] using [CameraPreviewWrapper].
/// - Use [BarcodeProcessor] to process the images from camera to find barcodes.
/// - Notify to the consumer widget.
/// [onCameraIsReady] : Callback when the camera is ready to use.
/// [onCameraIsStreaming] : Callback when the camera is streaming the image of each frame.
/// [onBarcodesFound] : Callback when some barcodes are found.
/// [onFailedToProcessBarcode] : Callback when an error occurs during processing the image to find barcode.
/// [originalPreferredOrientations] : See [CameraPreviewWrapper.originalPreferredOrientations].
/// [cameraControllerBuilder] : See [CameraPreviewWrapper.cameraControllerBuilder].
/// [barcodesBuilder] : Build barcode rectangles. See [BarcodesWidgetBuilder].
/// [barcodeFormats] : List of [BarcodeFormat] that are supported to find in an image.
/// [cameraPreviewSizeNotifier] : Is used to listen when it is able to get the image preview size of the camera.
class BarcodeScannerPreview extends StatefulWidget {
  final OnCameraIsReady? onCameraIsReady;
  final OnCameraIsStreaming? onCameraIsStreaming;
  final OnBarcodesFound? onBarcodesFound;
  final OnFailedToProcessBarcode? onFailedToProcessBarcode;
  final List<DeviceOrientation> originalPreferredOrientations;
  final BarcodesWidgetBuilder? barcodesBuilder;
  final CameraControllerBuilder cameraControllerBuilder;
  final List<BarcodeFormat>? barcodeFormats;

  final cameraPreviewSizeNotifier = ValueNotifier<Size>(Size.zero);

  BarcodeScannerPreview({
    super.key,
    required this.cameraControllerBuilder,
    this.onCameraIsReady,
    this.onCameraIsStreaming,
    this.onBarcodesFound,
    this.onFailedToProcessBarcode,
    required this.originalPreferredOrientations,
    this.barcodesBuilder,
    this.barcodeFormats,
  });

  @override
  State<BarcodeScannerPreview> createState() => _BarcodeScannerPreviewState();
}

class _BarcodeScannerPreviewState extends State<BarcodeScannerPreview> {
  BarcodeProcessor? barcodeProcessor;
  List<BarcodeX> barcodes = [];

  @override
  Widget build(BuildContext context) {
    return CameraPreviewWrapper(
      cameraControllerBuilder: widget.cameraControllerBuilder,
      originalPreferredOrientations: widget.originalPreferredOrientations,
      onCameraIsReady: onCameraIsReady,
      onCameraIsStreaming: onCameraIsStreaming,
      child: widget.barcodesBuilder != null
          ? widget.barcodesBuilder!(context, barcodes)
          : null,
    );
  }

  void onCameraIsReady(CameraController controller) {
    if (controller.value.previewSize != null) {
      widget.cameraPreviewSizeNotifier.value = controller.value.previewSize!;
    }

    _initBarcodeProcessor(controller);
    widget.onCameraIsReady?.call(controller);
  }

  void onCameraIsStreaming(CameraImage image) {
    if (barcodeProcessor != null) {
      barcodeProcessor!.processImage(image);
    }
    widget.onCameraIsStreaming?.call(image);
  }

  void onBarcodesFound(List<BarcodeX> barcodes) {
    if (mounted) {
      setState(() {
        this.barcodes = barcodes;
        widget.onBarcodesFound?.call(barcodes);
      });
    }
  }

  void _initBarcodeProcessor(CameraController controller) async {
    barcodeProcessor = BarcodeProcessor(
      cameraController: controller,
      onBarcodesFound: onBarcodesFound,
      barcodeFormats: widget.barcodeFormats,
      onFailedToProcessBarcode: widget.onFailedToProcessBarcode,
    );
  }
}
