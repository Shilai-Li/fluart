import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'serial_service.dart';
import 'serial_service_desktop.dart';
import 'serial_service_android.dart';

class SerialServiceFactory {
  static SerialService create() {
    if (kIsWeb) {
      throw UnsupportedError('Serial ports are not supported on web');
    }

    if (Platform.isAndroid) {
      return SerialServiceAndroid();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return SerialServiceDesktop();
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }
}
