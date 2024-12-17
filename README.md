# Romantic Project - Flutter Animated Barcode Scanner for Mobile Apps

This package makes it super easy to add barcode scanning to your mobile app. It comes with a animated barcode finder that guides users and highlights each barcode found with rectangles. It’s a powerful tool to make your app even better!

More packages by [Romantic Developer](https://pub.dev/publishers/romanticdeveloper.com/packages)

![Demo](./demo.gif)

## Key Features

- Easy Animated Barcode Scanner: Quickly add barcode scanning to your app with minimal setup.
- Cool Animated Finder: A animated finder that helps users easily scan barcodes.
- Smart Barcode Highlighting: Automatically shows rectangles around all detected barcodes.
- Customizable: Change the scanner's look and behavior to match your app’s style.
- Wide Barcode Support: Works with many types of barcodes for all kinds of uses.
- High Performance: Fast and accurate barcode scanning for a smooth user experience.

## Usage

See full implementation in the [example](https://github.com/minhhung2556/romantic_project_flutter_animated_barcode_scanner/tree/master/example) project.

```dart
BarcodeScannerPreviewWrapper(
    barcodeScannerPreview: BarcodeScannerPreview(
      cameraControllerBuilder: () async => CameraController(
        (await availableCameras()).first,
        Platform.isAndroid
            ? ResolutionPreset.high
            : ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
        fps: 25,
      ),
      originalPreferredOrientations: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
      ],
      barcodesBuilder: (context, barcodes) {
        return Stack(
          children: barcodes
              .map(
                (e) => BasicBarcodeRectangle(
                  cornerPoints: e.cornerPoints,
                  imageSize: e.imageSize,
                  color: Colors.green,
                  strokeWidth: 2,
                ),
              )
              .toList(growable: false),
        );
      },
      onCameraIsReady: (controller) {},
      onBarcodesFound: (barcodes) {},
      onCameraIsStreaming: (image) {},
      onFailedToProcessBarcode: (image, error, stace) {},
    ),
    mode: BarcodeScannerPreviewMode.square,
    finderWidget: AnimatedBarcodeFinder(
      lineColor: Colors.lightGreen,
      borderColor: Colors.lightGreenAccent,
      borderStrokeWidth: 4,
      lineStrokeWidth: 4,
    ),
  ),
)
```

## Development Environment

```
[!] Flutter (Channel stable, 3.24.3, on Microsoft Windows [Version 10.0.19045.5131], locale en-US)
    • Flutter version 3.24.3 on channel stable at C:\Users\admin\fvm\default
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 2663184aa7 (3 months ago), 2024-09-11 16:27:48 -0500
    • Engine revision 36335019a8
    • Dart version 3.5.3
    • DevTools version 2.37.3
```