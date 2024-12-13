import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_barcode_scanner/flutter_animated_barcode_scanner.dart';

const kPreferredOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(kPreferredOrientations);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/barcodeScanner': (context) => BarcodeScannerScreen(),
      },
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  BarcodeScannerPreviewMode mode = BarcodeScannerPreviewMode.square;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
        actions: BarcodeScannerPreviewMode.values
            .map(
              (e) => TextButton(
                child: Text(e.name),
                onPressed: () {
                  setState(() {
                    mode = e;
                  });
                },
              ),
            )
            .toList(growable: false),
      ),
      body: SingleChildScrollView(
        //because in fullscreen mode, the preview size is larger than screen size.
        child: BarcodeScannerPreviewWrapper(
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
            originalPreferredOrientations: kPreferredOrientations,
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
          mode: mode,
          finderWidget: AnimatedBarcodeFinder(
            lineColor: Colors.lightGreen,
            borderColor: Colors.lightGreenAccent,
            borderStrokeWidth: 4,
            lineStrokeWidth: 4,
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example'),
      ),
      body: Column(
        children: [
          FilledButton(
            onPressed: () {
              Navigator.pushNamed(context, '/barcodeScanner');
            },
            child: Text('Open barcode scanner'),
          ),
          FilledButton(
            onPressed: () {
              if (MediaQuery.of(context).orientation == Orientation.portrait) {
                SystemChrome.setPreferredOrientations(
                    kPreferredOrientations.reversed.toList(growable: false));
              } else {
                SystemChrome.setPreferredOrientations(kPreferredOrientations);
              }
            },
            child: const Text('Toggle Orientation'),
          ),
        ],
      ),
    );
  }
}
