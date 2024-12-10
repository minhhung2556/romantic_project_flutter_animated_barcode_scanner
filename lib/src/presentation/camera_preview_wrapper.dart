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

  const CameraPreviewWrapper({
    super.key,
    this.child,
    required this.onCameraIsReady,
    required this.onCameraIsStreaming,
    required this.originalPreferredOrientations,
  });

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

            final screenSize = MediaQuery.of(context).size;
            final pictureSize = cameraController!.value.previewSize!;
            late Size previewSize;
            if (screenSize.width < screenSize.height) {
              //device portrait.
              if (pictureSize.width > pictureSize.height) {
                //picture landscape.
                previewSize = screenSize;
              } else {
                //picture portrait.
                previewSize = Size(screenSize.height, screenSize.width);
              }
            } else {
              //device landscape.
              if (pictureSize.width > pictureSize.height) {
                //picture landscape.
                previewSize = Size(screenSize.height, screenSize.width);
              } else {
                //picture portrait.
                previewSize = screenSize;
              }
            }

            // fit to shortestSide of picture.
            previewSize = Size(
                screenSize.width, screenSize.width * pictureSize.aspectRatio);
            debugPrint(
                '_CameraPreviewWrapperState._buildCamera:\n #screenSize=$screenSize, ratio=${screenSize.aspectRatio}\n #pictureSize=$pictureSize, ratio=${pictureSize.aspectRatio}\n #previewSize=$previewSize, ratio=${previewSize.aspectRatio}');

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
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      debugPrint(
          '_CameraPreviewWrapperState._initializeCamera: sensorOrientation=${cameras.first.sensorOrientation}');
      ;
      await _controller.initialize();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      // _controller.setDescription(CameraDescription(name: cameras.first.name, lensDirection: cameras.first.lensDirection, sensorOrientation: 180));
      await _controller.startImageStream(widget.onCameraIsStreaming);
      return _controller;
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s,
          label: '_CameraPreviewWrapperState._initializeCamera.error: $e');
    }
    return null;
  }

  void _disposeCamera() {
    try {
      unawaited(cameraController?.dispose());
    } catch (e, s) {
      debugPrintStack(
          stackTrace: s,
          label:
              '_CameraPreviewWrapperState._disposeCamera._controller.error: $e');
    }
    cameraController = null;
  }

  @override
  Widget build(BuildContext context) {
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
