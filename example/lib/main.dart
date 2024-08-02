import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'qr_scanner_preview.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final BarcodeScanner barcodeScanner = BarcodeScanner();
  Barcode? barcode;
  final previewKey = GlobalKey();

  @override
  void dispose() {
    barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    print('_HomeState.build.screenSize: $screenSize');

    return Scaffold(
      appBar: AppBar(
        title: Text('Romantic Developer'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScannerPreview(
            key: previewKey,
            onImage: (e) {
              if (e != null) {
                _processImage(e);
              }
            },
            delayForNextImage: 1000,
          ),
          if (barcode != null) _buildForeground(context),
        ],
      ),
    );
  }

  Widget _buildForeground(BuildContext context) {
    final barcodeImageRect = barcode!.boundingBox;
    final previewRect = MediaQuery.of(context).size;
    final scaleX = previewRect.width / barcodeImageRect.width;
    final scaleY = previewRect.height / barcodeImageRect.height;
    print('_HomeState._buildForeground: $scaleX $scaleY');
    // final barcodeRect = MatrixUtils.transformRect(
    //     Matrix4.identity()
    //         .scaled(previewRect.width / barcodeImageRect.width, previewRect.height / barcodeImageRect.height),
    //     barcode!.boundingBox);
    final barcodeRect = Rect.fromCenter(
        center: barcodeImageRect.center.scale(scaleX, scaleY), width: previewRect.width, height: previewRect.height);
    print('_HomeState._buildForeground.barcodeRect: $barcodeRect');

    return Stack(
      children: [
        Positioned.fromRect(
          rect: barcodeRect,
          child: Container(
            color: Colors.purple.shade50,
          ),
        ),
      ],
    );
  }

  Future<void> _processImage(InputImage e) async {
    final res = await barcodeScanner.processImage(e);

    if (res.isNotEmpty) {
      final code = res.first;
      print('_HomeState._processImage.found: [${code.type}][${code.value}][${code.displayValue}]\n'
          'barcode.boundingBox: ${barcode?.boundingBox}\n'
          'barcode.cornerPoints: ${barcode?.cornerPoints}\n'
          'barcode.size: ${barcode?.boundingBox.size}\n'
          'image.size: ${e.metadata?.size}\n'
          'image.rotation: ${e.metadata?.rotation}');
      setState(() {
        barcode = code;
      });
    }
    barcodeScanner.close();
  }
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}
