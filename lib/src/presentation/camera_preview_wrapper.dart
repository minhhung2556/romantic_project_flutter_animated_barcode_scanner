import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../index.dart';

/// Wrapper of [CameraPreview] to show on screen easier.
/// [child] : See [CameraPreview.child].
/// [onCameraIsReady]
/// [onCameraIsStreaming]
/// [originalPreferredOrientations] : for the most popular UX of barcode scanner in every mobile app is in portrait mode. So this widget will force the app to portrait mode then re-apply the original orientation mode list of the main app.
/// [cameraControllerBuilder] : to build the [CameraController].
class CameraPreviewWrapper extends StatefulWidget {
  final Widget? child;
  final OnCameraIsReady onCameraIsReady;
  final OnCameraIsStreaming onCameraIsStreaming;
  final List<DeviceOrientation> originalPreferredOrientations;
  final CameraControllerBuilder cameraControllerBuilder;

  /// Constructor.
  const CameraPreviewWrapper({
    super.key,
    this.child,
    required this.onCameraIsReady,
    required this.onCameraIsStreaming,
    required this.originalPreferredOrientations,
    required this.cameraControllerBuilder,
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

  Future<CameraController?> _initializeCamera() async {
    debugPrint('_CameraPreviewWrapperState._initializeCamera');
    try {
      final controller = await widget.cameraControllerBuilder.call();
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.startImageStream(widget.onCameraIsStreaming);
      return controller;
    } catch (e, s) {
      debugPrintStack(
        stackTrace: s,
        label: '_CameraPreviewWrapperState._initializeCamera.error: $e',
      );
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
            '_CameraPreviewWrapperState._disposeCamera._controller.error: $e',
      );
    }
    cameraController = null;
  }

  @override
  Widget build(BuildContext context) {
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
