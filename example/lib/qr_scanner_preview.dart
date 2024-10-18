import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_qr_scanner/flutter_animated_qr_scanner.dart';
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
        widget.foreground ?? const AnimatedQRFinder(),
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
