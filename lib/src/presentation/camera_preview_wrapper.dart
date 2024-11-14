import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../index.dart';

class CameraPreviewWrapper extends StatefulWidget {
  final Widget? child;
  final OnCameraIsReady onCameraIsReady;
  final OnCameraIsStreaming onCameraIsStreaming;
  final List<DeviceOrientation> originalPreferredOrientations;

  const CameraPreviewWrapper(
      {super.key,
      this.child,
      required this.onCameraIsReady,
      required this.onCameraIsStreaming,
      required this.originalPreferredOrientations});

  @override
  State<CameraPreviewWrapper> createState() => _CameraPreviewWrapperState();
}

class _CameraPreviewWrapperState extends State<CameraPreviewWrapper> {
  CameraController? cameraController;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((duration) {
        _initializeCamera().then((e) {
          setState(() {
            cameraController = e;

            final size = MediaQuery.of(context).size;
            final pictureSize = cameraController!.value.previewSize!;
            late Size previewSize;
            if (MediaQuery.of(context).orientation == Orientation.portrait) {
              //device portrait.
              if (cameraController!.value.previewSize!.aspectRatio > 1) {
                //picture landscape.
                previewSize = size;
              } else {
                //picture portrait.
                previewSize = Size(size.height, size.width);
              }
            } else {
              //device landscape.
              if (cameraController!.value.previewSize!.aspectRatio > 1) {
                //picture landscape.
                previewSize = Size(size.height, size.width);
              } else {
                //picture portrait.
                previewSize = size;
              }
            }

            // fit to shortestSide of picture.
            late double ratio = pictureSize.longestSide / pictureSize.shortestSide;
            if (pictureSize.shortestSide == pictureSize.width) {
              previewSize = Size(previewSize.width, previewSize.width * ratio);
            } else {
              previewSize = Size(previewSize.height * ratio, previewSize.height);
            }
            print('_CameraPreviewWrapperState._buildCamera.screenSize=$size, ratio=${size.aspectRatio}');
            print('_CameraPreviewWrapperState._buildCamera.pictureSize=$pictureSize, ratio=${pictureSize.aspectRatio}');
            print('_CameraPreviewWrapperState._buildCamera.previewSize=$previewSize, ratio=${previewSize.aspectRatio}');

            widget.onCameraIsReady(cameraController!, pictureSize, previewSize);
          });
        });
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _disposeCamera();
    SystemChrome.setPreferredOrientations(widget.originalPreferredOrientations);
    super.dispose();
  }

  Future<CameraController?> _initializeCamera() async {
    debugPrint('_CameraPreviewWrapperState._initializeCamera');
    try {
      final cameras = await availableCameras();
      var _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller.initialize();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _controller.startImageStream(widget.onCameraIsStreaming);
      return _controller;
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: '_CameraPreviewWrapperState._initializeCamera.error: $e');
    }
    return null;
  }

  void _disposeCamera() {
    try {
      unawaited(cameraController?.dispose());
    } catch (e, s) {
      debugPrintStack(stackTrace: s, label: '_CameraPreviewWrapperState._disposeCamera._controller.error: $e');
    }
    cameraController = null;
  }

  @override
  Widget build(BuildContext context) {
    print('_CameraPreviewWrapperState.build.widgetSize: ${MediaQuery.sizeOf(context)}');
    return _buildCamera(context);
  }

  Widget _buildCamera(BuildContext context) {
    if (cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return SingleChildScrollView(
        child: CameraPreview(
          cameraController!,
          child: widget.child,
        ),
      );
    }
  }
}
