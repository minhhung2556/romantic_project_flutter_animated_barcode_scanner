import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../index.dart';

/// [kCameraPreviewRouteObserver] : It is required to register this observer to let the camera preview widget know when the route changes then it will stop/start the camera for reducing the camera resource usage.
final RouteObserver<ModalRoute> kCameraPreviewRouteObserver =
    RouteObserver<ModalRoute>();

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
  final Widget? placeHolderCameraUnavailable;
  final Widget? placeHolderCameraInitializing;

  /// Constructor.
  const CameraPreviewWrapper({
    super.key,
    this.child,
    required this.onCameraIsReady,
    required this.onCameraIsStreaming,
    required this.originalPreferredOrientations,
    required this.cameraControllerBuilder,
    this.placeHolderCameraUnavailable,
    this.placeHolderCameraInitializing,
  });

  @override
  State<CameraPreviewWrapper> createState() => _CameraPreviewWrapperState();
}

class _CameraPreviewWrapperState extends State<CameraPreviewWrapper>
    with RouteAware, WidgetsBindingObserver {
  static const String kTAG = 'CameraPreviewWrapperState';
  CameraController? cameraController;
  bool? cameraAvailable;
  bool _isCameraInitializing = false;

  @override
  void didChangeDependencies() {
    kCameraPreviewRouteObserver.subscribe(
        this, ModalRoute.of(context)! as PageRoute<dynamic>);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    debugPrint('$kTAG.initState');
    WidgetsBinding.instance.addObserver(this);
    _checkCameraAvailable().then((_) {
      if (cameraAvailable == true) {
        _setupCamera();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    debugPrint('$kTAG.dispose');
    _disposeCamera();
    WidgetsBinding.instance.removeObserver(this);
    kCameraPreviewRouteObserver.unsubscribe(this);
    SystemChrome.setPreferredOrientations(widget.originalPreferredOrientations);
    super.dispose();
  }

  /// Initializes and sets up the camera.
  /// It sets the preferred orientation to portrait mode, then initializes the camera.
  /// If the camera initialization is successful, it updates the state with the new [CameraController].
  void _setupCamera() {
    debugPrint('$kTAG._setupCamera');
    if (_isCameraInitializing) {
      debugPrint('$kTAG._setupCamera: already initializing.');
      return;
    }

    if (cameraAvailable == true) {
      _isCameraInitializing = true;
      if (cameraController != null) {
        _disposeCamera(); // Dispose existing controller before creating a new one
      }

      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((duration) async {
          try {
            final controller = await widget.cameraControllerBuilder.call();
            await controller.initialize();
            // Ensure orientation is locked before starting the preview or image stream
            await controller
                .lockCaptureOrientation(DeviceOrientation.portraitUp);

            // Check if the widget is still mounted and camera controller is not null
            if (mounted && cameraController == null) {
              // Check cameraController == null to avoid re-assigning if dispose was called during init
              await controller.startImageStream((image) {
                if (mounted &&
                    controller.value.isInitialized &&
                    controller.value.isStreamingImages) {
                  widget.onCameraIsStreaming.call(image);
                } else {
                  debugPrint(
                    '$kTAG._initializeCamera: camera is pausing or disposed, but image stream is still active.',
                  );
                }
              });
              cameraController = controller;
              debugPrint('$kTAG._initializeCamera.onCameraIsReady');
              widget.onCameraIsReady(cameraController!);
            } else {
              // If not mounted or controller already exists (e.g., due to quick lifecycle changes), dispose the new controller
              debugPrint(
                '$kTAG._initializeCamera: unmounted or controller already exists. Disposing new controller.',
              );
              await controller.dispose();
            }
          } catch (e, s) {
            debugPrintStack(
              stackTrace: s,
              label: '$kTAG._initializeCamera.error: $e',
            );
            // Handle specific camera exceptions if needed, e.g., by setting cameraAvailable = false
          } finally {
            _isCameraInitializing = false;
            if (mounted) {
              setState(
                  () {}); // Update UI regardless of success or failure to reflect camera state
            }
          }
        });
      });
    }
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off the screen and this route is now visible.
    debugPrint('$kTAG.didPopNext');
    _setupCamera();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    // Called when the current route has been pushed off the screen by another route.
    debugPrint('$kTAG.didPushNext');

    /// Prevent background camera preview and image stream when the route is pushed.
    /// Also prevent the camera still alive if a new route would be replaced and route stack is popped.
    _disposeCamera();
    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle for AppState changes.
    debugPrint('$kTAG.didChangeAppLifecycleState: $state');
    final controller =
        cameraController; // Local variable to avoid race conditions with async operations
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.resumed:
        // Check if the current screen, parent of this widget, is not the current screen, then return
        // This prevents the camera from being initialized when the app is resumed but the screen is not visible
        if (ModalRoute.of(context)?.isCurrent == false) {
          return;
        }

        if (controller == null ||
            controller.value.isInitialized == false ||
            controller.value.hasError) {
          debugPrint(
            '$kTAG.didChangeAppLifecycleState: the camera is not ready to resume the app. So setup it again.',
          );
          _setupCamera();
        } else {
          debugPrint(
              '$kTAG.didChangeAppLifecycleState: the camera is still good to use.');
          if (controller.value.isStreamingImages == false) {
            debugPrint(
                '$kTAG.didChangeAppLifecycleState: re-stream the image.');
            unawaited(
              controller.startImageStream((image) {
                if (mounted &&
                    controller.value.isInitialized &&
                    controller.value.isStreamingImages) {
                  widget.onCameraIsStreaming.call(image);
                } else {
                  debugPrint(
                    '$kTAG._initializeCamera: camera is pausing or disposed, but image stream is still active.',
                  );
                }
              }).catchError((e, s) {
                debugPrintStack(
                  stackTrace: s,
                  label:
                      '$kTAG.didChangeAppLifecycleState.startImageStream.error: $e',
                );
              }),
            );
          }
          if (controller.value.isPreviewPaused == true) {
            debugPrint('$kTAG.didChangeAppLifecycleState: resume the preview.');
            unawaited(
              controller.resumePreview().catchError((e, s) {
                debugPrintStack(
                    stackTrace: s,
                    label:
                        '$kTAG.didChangeAppLifecycleState.resumePreview.error: $e');
              }),
            );
          }
        }
        break;
    }
  }

  /// Disposes the [CameraController] to release camera resources.
  void _disposeCamera() {
    debugPrint('$kTAG._disposeCamera');
    final controllerToDispose = cameraController;
    cameraController = null; // Set to null immediately to prevent further use

    try {
      // ignore: prefer_void_to_null
      // Ensure controller is not null and is initialized before trying to stop stream or dispose
      if (controllerToDispose != null &&
          controllerToDispose.value.isInitialized) {
        // Check if preview is paused before trying to pause it.
        if (controllerToDispose.value.isPreviewPaused == false) {
          unawaited(
            controllerToDispose.pausePreview().catchError((e, s) {
              debugPrintStack(
                stackTrace: s,
                label: '$kTAG._disposeCamera.pausePreview.error: $e',
              );
            }),
          );
        }
        // Check if image streaming is active before trying to stop it
        if (controllerToDispose.value.isStreamingImages) {
          unawaited(
            controllerToDispose.stopImageStream().catchError((e, s) {
              debugPrintStack(
                stackTrace: s,
                label: '$kTAG._disposeCamera.stopImageStream.error: $e',
              );
            }),
          );
        }
        unawaited(
          controllerToDispose.dispose().catchError((e, s) {
            debugPrintStack(
                stackTrace: s, label: '$kTAG._disposeCamera.dispose.error: $e');
          }),
        );
      }
    } catch (e, s) {
      debugPrintStack(
        stackTrace: s,
        label: '$kTAG._disposeCamera._controller.error: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cameraAvailable == null ||
        (cameraAvailable == true &&
            (cameraController == null ||
                !cameraController!.value.isInitialized))) {
      // Show initializing placeholder while checking for camera availability or while the camera is initializing.
      return widget.placeHolderCameraInitializing ??
          Container(color: Colors.black12);
    } else if (cameraAvailable == false) {
      // Show unavailable placeholder if the camera is not available.
      return Center(
          child: widget.placeHolderCameraInitializing ??
              Text(
                'Camera is not available!',
                style: Theme.of(context).textTheme.labelMedium,
              ));
    } else {
      // Show the camera preview once the camera is initialized.
      return SingleChildScrollView(
        child: CameraPreview(
          cameraController!,
          child: widget.child,
        ),
      );
    }
  }

  /// Checks if any cameras are available on the device.
  Future<void> _checkCameraAvailable() async {
    debugPrint('$kTAG._checkCameraAvailable');
    try {
      final cameraList = await availableCameras();
      cameraAvailable = cameraList.isNotEmpty;
    } on CameraException catch (_) {
      // camera not found
      cameraAvailable = false;
    } on Exception catch (_) {
      // unexpected camera error
      cameraAvailable = false;
    }
    if (mounted) {
      setState(() {});
    }
  }
}
