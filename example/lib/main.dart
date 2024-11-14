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
      theme: ThemeData.from(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/barcodeScanner': (context) => BarcodeScannerScreen(),
      },
    );
  }
}

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
      ),
      body: Column(
        children: [
          SizedBox.square(
            dimension: MediaQuery.of(context).size.shortestSide,
            child: BarcodeScannerPreview(
              originalPreferredOrientations: kPreferredOrientations,
            ),
          ),
        ],
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
                SystemChrome.setPreferredOrientations(kPreferredOrientations.reversed.toList(growable: false));
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
