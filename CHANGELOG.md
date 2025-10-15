## [2.0.0] - 14/10/2025

* **Breaking Changes**: 
  * Upgraded dependencies to their latest versions.
  * The library now enforces its default camera controller to simplify usage and improve stability. This change provides the following benefits:
    * Simplified API, making the scanner easier to implement.
    * Automatic camera lifecycle management handled by the library.
    * The back camera is now the only option, targeting the most common use case.
* **New Features**:
  * Added `BarcodeScannerPreview.customInputImageFormat` to allow customizing the input image format on a per-device model basis. This addresses issues on certain Android devices that do not default to the `nv21` format.
* **Performance Improvements**:
  * Optimized resource usage by automatically managing the camera's state (start, stop, re-initialize) in response to the application and screen lifecycle events.

## [1.0.0] - 17/12/2024

* First release version.
