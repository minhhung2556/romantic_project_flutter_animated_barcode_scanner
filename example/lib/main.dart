import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animated_qr_scanner/flutter_animated_qr_scanner.dart';

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
  CameraController? cameraController;

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
            onCameraIsReady: (cameraController) => setState(() {
              this.cameraController = cameraController;
            }),
            originalPreferredOrientations: kPreferredOrientations,
            barcodesBuilder: (context, barcodes) {
              return Stack(
                children: barcodes
                    .map(
                      (e) => BasicBarcodeRectangle(
                        cornerPoints: e.cornerPoints,
                        imageSize: e.imageSize,
                        color: Colors.deepOrange,
                        strokeWidth: 2,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          cameraController: cameraController,
          mode: mode,
          finderWidget: AnimatedQRFinder(
            lineColor: Colors.green,
            borderColor: Colors.greenAccent,
            borderStrokeWidth: 2,
            lineStrokeWidth: 1,
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
