import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// [ScannerPreview] Preview widget for QR Scanner.
/// [delayForNextImage] : delay for next image processing, in milliseconds.
/// [foreground] : is front of [CameraPreview].
/// [onImage] : returns qr image data to parent to check.
class ScannerPreview extends StatefulWidget {
  final Function(InputImage? inputImage) onImage;
  final int delayForNextImage;
  final Widget? foreground;

  const ScannerPreview({
    Key? key,
    required this.onImage,
    this.delayForNextImage = 500,
    this.foreground,
  }) : super(key: key);

  @override
  State<ScannerPreview> createState() => _ScannerPreviewState();
}

class _ScannerPreviewState extends State<ScannerPreview> with RouteAware {
  late CameraController? _controller;
  bool isInitCameraDone = false;
  bool startStream = true;
  late List<CameraDescription> cameras;

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      final cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      _controller = cameraController;
      await _controller?.initialize();
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
      print('Exception Error Initialize Camera $e $s');
    }
  }

  Future _disposeCamera() async {
    if (_controller?.value.isInitialized == true) {
      await _controller?.stopImageStream();
      await _controller?.dispose();
    }
    setState(() {
      isInitCameraDone = false;
      _controller = null;
    });
  }

  @override
  void initState() {
    _initializeCamera();
    super.initState();
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
    super.dispose();
  }

  Future _processCameraImage(CameraImage image) async {
    try {
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final camera = cameras[0];
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw as int) ?? InputImageFormat.bgra8888;

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
      print('Unexpected error in processing camera image $e $s');
      return e;
    } catch (e, s) {
      print('Unexpected error in processing camera image $e $s');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCamera(context),
        widget.foreground ?? const DefaultQRFinder(),
        Column(
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _disposeCamera();
                    },
                    child: Text(
                      'Stop',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _initializeCamera();
                    },
                    child: Text(
                      'Restart',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get isCameraInitialized => isInitCameraDone && _controller!.value.isInitialized;

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
    final borderColor = Colors.white;
    final qrFinderRectDimension = MediaQuery.of(context).size.width - apertureEdge * 2;
    final x = max(0.0, qrFinderRectDimension - viewFinderEdge);
    return Stack(
      fit: StackFit.expand,
      children: [
        // background
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut),
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
          padding: EdgeInsets.only(left: x, bottom: x),
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
          padding: EdgeInsets.only(right: x, bottom: x),
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
          padding: EdgeInsets.only(left: x, top: x),
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
          padding: EdgeInsets.only(right: x, top: x),
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
