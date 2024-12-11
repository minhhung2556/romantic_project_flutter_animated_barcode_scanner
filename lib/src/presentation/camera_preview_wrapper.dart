import 'dart:async';
import 'dart:io';

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
            widget.onCameraIsReady(cameraController!);
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

  bool get isAndroid => Platform.isAndroid;

  Future<CameraController?> _initializeCamera() async {
    // if the image quality is medium then on android the [BarcodeScanner] can not recognize any qr codes.
    debugPrint('_CameraPreviewWrapperState._initializeCamera');
    try {
      final cameras = await availableCameras();
      var _controller = CameraController(
        cameras.first,
        isAndroid ? ResolutionPreset.high : ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
        fps: 25,
      );
      await _controller.initialize();
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
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
