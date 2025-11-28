import 'package:flutter/foundation.dart';
import 'serial_service.dart';
import 'serial_service_desktop.dart'
    if (dart.library.html) 'serial_service_desktop_stub.dart';
import 'serial_service_android.dart'
    if (dart.library.html) 'serial_service_android_stub.dart';
import 'serial_service_web_stub.dart'
    if (dart.library.html) 'serial_service_web.dart';

class SerialServiceFactory {
  static SerialService create() {
    if (kIsWeb) {
      return SerialServiceWeb();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return SerialServiceAndroid();
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return SerialServiceDesktop();
      default:
        throw UnsupportedError(
          'Platform $defaultTargetPlatform is not supported',
        );
    }
  }
}
