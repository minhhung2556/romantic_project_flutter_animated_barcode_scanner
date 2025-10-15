import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_barcode_scanner/flutter_animated_barcode_scanner.dart';

/// The preferred orientations for this app.
const kPreferredOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
];

/// The main entry point of the application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(kPreferredOrientations);
  runApp(MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates the root application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The [kCameraPreviewRouteObserver] is used to stop/start the camera
    // when the route changes.
    return MaterialApp(
      title: 'Example',
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/barcodeScanner': (context) => BarcodeScannerScreen(),
        '/dummy': (context) => DummyScreen(),
      },
      navigatorObservers: [kCameraPreviewRouteObserver],
    );
  }
}

/// A screen that displays a barcode scanner.
class BarcodeScannerScreen extends StatefulWidget {
  /// Creates a [BarcodeScannerScreen].
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  BarcodeScannerPreviewMode mode = BarcodeScannerPreviewMode.square;
  bool animatingFinder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
        actions: BarcodeScannerPreviewMode.values
            .map<Widget>(
              (e) => TextButton(
                child: Text(e.name),
                onPressed: () {
                  setState(() {
                    mode = e;
                  });
                },
              ),
            )
            .toList(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxMenuButton(
            value: animatingFinder,
            onChanged: (e) {
              setState(() {
                animatingFinder = e ?? false;
              });
            }, child: Text('AnimatingFinder'),
          ),
          Expanded(
            child: BarcodeScannerPreviewWrapper(
              barcodeScannerPreview: BarcodeScannerPreview(
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
                // All the callbacks below are optional.
                // You can safely remove them if you don't need them.
                onCameraIsReady: (controller) {},
                onBarcodesFound: (barcodes) {},
                onCameraIsStreaming: (image) {},
                onFailedToProcessBarcode: (image, error, stace) {},
              ),
              mode: mode,
              finderWidget: animatingFinder == true
                  ? AnimatedBarcodeFinder()
                  : AnimatedBarcodeFinder.static(
                      hasLine: false,
                      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      "Scan any barcodes",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dummy');
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }
}

/// The home screen of the example application.
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen].
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

/// A dummy screen to demonstrate navigation from the barcode scanner screen.
class DummyScreen extends StatelessWidget {
  /// Creates a [DummyScreen].
  const DummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DummyScreen'),
      ),
      body: Placeholder(),
    );
  }
}
