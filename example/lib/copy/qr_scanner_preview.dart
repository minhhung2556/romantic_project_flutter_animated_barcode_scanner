/*
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gma_platform/gma_platform.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:koyal_core/koyal_core.dart';
import 'package:koyal_shared/koyal_shared.dart';
import 'package:koyal_ui/koyal_ui.dart';
import 'package:logger/logger.dart';

import 'camera_extension.dart';

/// [ScannerPreview] Preview widget for QR Scanner.
/// [delayForNextImage] : delay for next image processing, in milliseconds.
/// [foreground] : is front of [CameraPreview].
/// [onImage] : returns qr image data to parent to check.
class ScannerPreview extends StatefulWidget {
  final Function(InputImage? inputImage) onImage;
  final int delayForNextImage;
  final Widget? foreground;
  final ICrashlyticsInitService crashlyticsInitService;

  const ScannerPreview({
    Key? key,
    required this.onImage,
    this.delayForNextImage = 500,
    this.foreground,
    required this.crashlyticsInitService,
  }) : super(key: key);

  @override
  State<ScannerPreview> createState() => _ScannerPreviewState();
}

class _ScannerPreviewState extends State<ScannerPreview> with RouteAware, WidgetsBindingObserver {
  late KoyalRouterObserver _observer;
  late CameraController? _controller;
  bool isInitCameraDone = false;
  bool startStream = true;
  late List<CameraDescription> cameras;
  final Logger _logger = Logger();

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      final cameraController = CameraController(
        cameras[0],
        GmaPlatform.isIOS ? ResolutionPreset.high : ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: GmaPlatform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      _controller = cameraController;
      await _controller!.initialize();
      if (!context.mounted) return;
      setState(() {
        isInitCameraDone = true;
      });
      await _controller!.startImageStream((image) {
        if (!startStream) return;
        startStream = false;
        _processCameraImage(image);
        Timer(Duration(milliseconds: widget.delayForNextImage), () => startStream = true);
      });
    } catch (e, s) {
      widget.crashlyticsInitService
          .sendReport(exception: e, stackTrace: s, reason: 'Exception Error Initialize Camera $e;');
      _logger.e('Exception Error Initialize Camera $e');
    }
  }

  @override
  void didChangeDependencies() {
    _observer.subscribe(this, ModalRoute.of(context)! as PageRoute<dynamic>);
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !(_controller?.value.isInitialized ?? false)) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _disposeCamera() async {
    try {
      if (context.mounted) {
        setState(() {
          isInitCameraDone = false;
        });
      }
      if (_controller?.value.isInitialized == true) {
        await _controller?.dispose();
      }
      _controller = null;
    } catch (e, s) {
      widget.crashlyticsInitService.sendReport(
        exception: e,
        stackTrace: s,
        reason: 'Unexpected error disposing camera $e',
      );
      _logger.e('Unexpected error disposing camera', e);
    }
  }

  @override
  void initState() {
    _initializeCamera();
    _observer = context.get<KoyalRouterObserver>();
    super.initState();
  }

  @override
  void didPop() {
    _disposeCamera();
    super.didPop();
  }

  @override
  void didPopNext() {
    _initializeCamera();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    _disposeCamera();
    super.didPushNext();
  }

  @override
  void dispose() {
    _disposeCamera();
    _observer.unsubscribe(this);
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      var inputImageFormat = _getInputImageFormat(image.format.group);
      var bytes = allBytes.done().buffer.asUint8List();
      if (GmaPlatform.isAndroid && InputImageFormat.yuv420 == inputImageFormat) {
        inputImageFormat = InputImageFormat.nv21;
        bytes = image.getNv21Uint8List();
      }
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = cameras[0];
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
      widget.onImage(inputImage);
    } on Exception catch (e, s) {
      widget.crashlyticsInitService.sendReport(
        exception: e,
        stackTrace: s,
        reason: 'Exception Error Initialize Camera $e;',
      );
      _logger.e('Unexpected error in processing camera image', e);
    } catch (e, s) {
      widget.crashlyticsInitService.sendReport(
        exception: e,
        stackTrace: s,
        reason: 'Exception Error Initialize Camera $e;',
      );
      _logger.e('Unexpected error in processing camera image', e);
    }
  }

  InputImageFormat _getInputImageFormat(ImageFormatGroup formatGroup) {
    switch (formatGroup) {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCamera(context),
        widget.foreground ?? const DefaultQRFinder(),
      ],
    );
  }

  bool get isCameraInitialized => isInitCameraDone && (_controller?.value.isInitialized ?? false);

  Widget _buildCamera(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: isCameraInitialized == false
              ? null
              : Transform.scale(
                  scale: (size.aspectRatio * _controller!.value.aspectRatio) < 1
                      ? 1 / (size.aspectRatio * _controller!.value.aspectRatio)
                      : size.aspectRatio * _controller!.value.aspectRatio,
                  alignment: FractionalOffset.center,
                  child: Center(
                    child: CameraPreview(_controller!),
                  ),
                ),
        );
      },
    );
  }
}

/// [DefaultQRFinder] : default design for QR scanner.
/// [apertureEdge] : margin of [CameraPreview] to the screen.
/// [viewFinderEdge] : center of camera let the users places to the QR code picture, it is the length of white border lines.
/// [child] : is front of this, and inside the  finder rectangle.
class DefaultQRFinder extends StatelessWidget {
  final double apertureEdge;
  final double viewFinderEdge;
  final Widget? child;

  const DefaultQRFinder({
    super.key,
    this.apertureEdge = 32.0,
    this.viewFinderEdge = 48.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = ColorTheme.of(context).backgroundColor;
    final qrFinderRectDimension = MediaQuery.of(context).size.width - apertureEdge * 2;
    return Stack(
      fit: StackFit.expand,
      children: [
        // background
        ColorFiltered(
          // ignore: no-hcicolors
          colorFilter: ColorFilter.mode(HciColors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                // ignore: no-hcicolors
                decoration: const BoxDecoration(color: HciColors.black, backgroundBlendMode: BlendMode.dstOut),
              ),
              // add a mask for qr finder rectangle.
              Align(
                child: Container(
                  width: qrFinderRectDimension,
                  height: qrFinderRectDimension,
                  padding: EdgeInsets.all(apertureEdge),
                  color: borderColor, // any color.
                ),
              ),
            ],
          ),
        ),
        // top-right border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            left: qrFinderRectDimension - viewFinderEdge,
            bottom: qrFinderRectDimension - viewFinderEdge,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 2),
                right: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
        // top-left border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            right: qrFinderRectDimension - viewFinderEdge,
            bottom: qrFinderRectDimension - viewFinderEdge,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 2),
                left: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
        // bottom-right border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            left: qrFinderRectDimension - viewFinderEdge,
            top: qrFinderRectDimension - viewFinderEdge,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 2),
                right: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
        // bottom-left border
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            right: qrFinderRectDimension - viewFinderEdge,
            top: qrFinderRectDimension - viewFinderEdge,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 2),
                left: BorderSide(color: borderColor, width: 2),
              ),
            ),
            width: viewFinderEdge,
            height: viewFinderEdge,
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
*/
