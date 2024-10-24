import '../index.dart';

typedef OnBarcodesFoundCallback = void Function(List<BarcodeX> barcodes);
typedef OnFailedToDoSomething = void Function(Object? e, StackTrace? s);
