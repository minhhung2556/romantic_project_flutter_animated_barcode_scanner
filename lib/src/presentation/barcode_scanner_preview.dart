import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../index.dart';

/// on some Android devices, they return images in [ImageFormatGroup.bgra8888].
const _kInputImageFormatSwitchingList = [
  ImageFormatGroup.nv21,
  ImageFormatGroup.bgra8888,
  ImageFormatGroup.yuv420,
  ImageFormatGroup.jpeg,
  ImageFormatGroup.unknown,
];

/// NOTE:
/// - If the image quality is medium then on android the [BarcodeScanner] can not recognize any qr codes.
/// BarcodeScannerPreview helps in handling the barcode scanner widget:
/// - Draw the [CameraPreview] using [CameraPreviewWrapper].
/// - Use [BarcodeProcessor] to process the images from camera to find barcodes.
/// - Notify to the consumer widget.
///
class BarcodeScannerPreview extends StatefulWidget {
  /// Callback when the camera is ready to use.
  final OnCameraIsReady? onCameraIsReady;

  /// Callback when the camera is streaming the image of each frame.
  final OnCameraIsStreaming? onCameraIsStreaming;

  /// Callback when some barcodes are found.
  final OnBarcodesFound? onBarcodesFound;

  /// Callback when an error occurs during processing the image to find barcode.
  final OnFailedToProcessBarcode? onFailedToProcessBarcode;

  /// See [CameraPreviewWrapper.originalPreferredOrientations].
  final List<DeviceOrientation> originalPreferredOrientations;

  /// Build barcode rectangles. See [BarcodesWidgetBuilder].
  final BarcodesWidgetBuilder? barcodesBuilder;

  /// List of [BarcodeFormat] that are supported to find in an image.
  final List<BarcodeFormat>? barcodeFormats;

  /// Only Android is affected. The preview will use by switching one by one in
  /// [_kInputImageFormatSwitchingList] every [automaticallySwitchingImageFormatDuration].
  ///
  /// Set to [Duration.zero] to disable this feature.
  ///
  /// This job allows the app to work correctly on as many Android devices as
  /// possible by cycling through different image formats.
  final Duration automaticallySwitchingImageFormatDuration;

  /// Is used to listen when it is able to get the image preview size of the camera.
  final cameraPreviewSizeNotifier = ValueNotifier<Size>(Size.zero);

  /// If [customInputImageFormat] is null then [ImageFormatGroup.unknown] will
  /// be used by default. And later [onCameraIsStreaming] the input image format
  /// will be detected in the [CameraImage.format].
  ///
  /// According to data collected on Production, here are devices that must have
  /// a custom input image format:
  ///  - [ImageFormatGroup.bgra8888] :
  ///    - CPH2333 - OPPO A96
  ///    - CPH2343 - OPPO Reno7
  ///    - CPH2505 - OPPO Reno8
  ///    - CPH2363 - OPPO Reno7
  ///    - CPH2365 - OPPO A95
  ///    - CPH2375 - OPPO A76
  ///    - SM-A235F - Samsung Galaxy A23
  final ImageFormatGroup? customInputImageFormat;

  BarcodeScannerPreview({
    super.key,
    this.onCameraIsReady,
    this.onCameraIsStreaming,
    this.onBarcodesFound,
    this.onFailedToProcessBarcode,
    required this.originalPreferredOrientations,
    this.barcodesBuilder,
    this.barcodeFormats,
    this.automaticallySwitchingImageFormatDuration = Duration.zero,
    this.customInputImageFormat,
  });

  @override
  State<BarcodeScannerPreview> createState() => _BarcodeScannerPreviewState();
}

class _BarcodeScannerPreviewState extends State<BarcodeScannerPreview>
    with RouteAware, WidgetsBindingObserver {
  BarcodeProcessor? barcodeProcessor;
  List<BarcodeX> barcodes = [];

  int inputImageFormatSelectedIndex = 0;
  final inputImageFormatStream = StreamController<ImageFormatGroup>();
  Timer? _timer;

  Future<CameraController> _createCameraController(
    ImageFormatGroup? format,
  ) async {
    debugPrint(
      '_BarcodeScannerPreviewState._createCameraController: with $format',
    );
    return CameraController(
      (await availableCameras()).first,
      Platform.isAndroid ? ResolutionPreset.high : ResolutionPreset.medium,
      enableAudio: false,
      fps: 25,
      imageFormatGroup: format,
    );
  }

  @override
  void didUpdateWidget(covariant BarcodeScannerPreview oldWidget) {
    if (oldWidget.automaticallySwitchingImageFormatDuration != Duration.zero &&
        widget.automaticallySwitchingImageFormatDuration == Duration.zero) {
      _stopTimer();
    } else if (oldWidget.automaticallySwitchingImageFormatDuration ==
            Duration.zero &&
        widget.automaticallySwitchingImageFormatDuration != Duration.zero) {
      _startTimer();
    }
    if (oldWidget.customInputImageFormat != widget.customInputImageFormat &&
        widget.customInputImageFormat != null) {
      inputImageFormatStream.add(widget.customInputImageFormat!);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off the screen and this route is now visible.
    _startTimer();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    // Called when the current route has been pushed off the screen by another route.
    // Prevent background camera preview and image stream when the route is pushed.
    // Also prevent the camera still alive if a new route would be replaced and route stack is popped.
    _stopTimer();
    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle for AppState changes.
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopTimer();
        break;
      case AppLifecycleState.resumed:
        // Check if the current screen, parent of this widget, is not the current screen, then return
        // This prevents the camera from being initialized when the app is resumed but the screen is not visible
        if (ModalRoute.of(context)?.isCurrent == false) {
          return;
        }
        _startTimer();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: inputImageFormatStream.stream,
      initialData: widget.customInputImageFormat,
      builder: (context, snapshot) {
        return CameraPreviewWrapper(
          key: ValueKey(snapshot.data),
          cameraControllerBuilder: () => _createCameraController(snapshot.data),
          originalPreferredOrientations: widget.originalPreferredOrientations,
          onCameraIsReady: (controller) => _onCameraIsReady(
            controller,
            snapshot.data?.toMLKitInputImageFormat,
          ),
          onCameraIsStreaming: _onCameraIsStreaming,
          child: widget.barcodesBuilder?.call(context, barcodes),
        );
      },
    );
  }

  void _onCameraIsReady(
    CameraController controller, [
    InputImageFormat? inputImageFormat,
  ]) {
    if (controller.value.previewSize != null) {
      final size = controller.value.previewSize!;
      debugPrint('_BarcodeScannerPreviewState._onCameraIsReady.previewSize: $size');
      widget.cameraPreviewSizeNotifier.value = size;
    }

    _initBarcodeProcessor(controller, inputImageFormat);
    widget.onCameraIsReady?.call(controller);
  }

  void _onCameraIsStreaming(CameraImage image) {
    if (barcodeProcessor != null) {
      barcodeProcessor!.processImage(image);
    }
    widget.onCameraIsStreaming?.call(image);
  }

  void _onBarcodesFound(List<BarcodeX> barcodes) {
    if (mounted) {
      setState(() {
        this.barcodes = barcodes;
        widget.onBarcodesFound?.call(barcodes);
      });
    }
  }

  void _initBarcodeProcessor(
    CameraController controller, [
    InputImageFormat? inputImageFormat,
  ]) {
    debugPrint(
      '_BarcodeScannerPreviewState._initBarcodeProcessor: with $inputImageFormat',
    );

    barcodeProcessor = BarcodeProcessor(
      cameraController: controller,
      onBarcodesFound: _onBarcodesFound,
      barcodeFormats: widget.barcodeFormats,
      onFailedToProcessBarcode: widget.onFailedToProcessBarcode,
      inputImageFormat: inputImageFormat,
    );
  }

  void _startTimer() {
    if (widget.automaticallySwitchingImageFormatDuration == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(widget.automaticallySwitchingImageFormatDuration,
        (timer) {
      inputImageFormatSelectedIndex++;
      if (inputImageFormatSelectedIndex ==
          _kInputImageFormatSwitchingList.length) {
        inputImageFormatSelectedIndex = 0;
      }
      final inputImageFormat =
          _kInputImageFormatSwitchingList[inputImageFormatSelectedIndex];
      debugPrint(
        '_BarcodeScannerPreviewState.switchingInputImageFormatTimer: switch to $inputImageFormat',
      );

      inputImageFormatStream.add(inputImageFormat);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
