import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'serial_service.dart';

class SerialServiceWeb implements SerialService {
  dynamic _port;
  dynamic _reader;
  dynamic _writer;

  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;

  // Map to store port objects (dynamic JS objects)
  final Map<String, dynamic> _knownPorts = {};

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  @override
  Future<List<String>> getAvailablePorts() async {
    final nav = html.window.navigator;
    if (!js_util.hasProperty(nav, 'serial')) {
      return ['Web Serial API not supported'];
    }

    try {
      final serial = js_util.getProperty(nav, 'serial');
      final portsPromise = js_util.callMethod(serial, 'getPorts', []);
      final ports = await js_util.promiseToFuture(portsPromise);

      _knownPorts.clear();
      final List<String> portNames = [];

      // ports is a JS Array. We can iterate it using List.from if it's iterable,
      // or standard loop if it's a JS array.
      // Usually List.from(ports) works for JS arrays in Dart web.
      final portsList = List.from(ports as List);

      for (var i = 0; i < portsList.length; i++) {
        final port = portsList[i];
        final name = "WebPort-$i";
        _knownPorts[name] = port;
        portNames.add(name);
      }

      if (portNames.isEmpty) {
        return ['Select Port...'];
      }

      return portNames;
    } catch (e) {
      print('Error getting ports: $e');
      return ['Select Port...'];
    }
  }

  @override
  Future<bool> connect(
    String portName, {
    int baudRate = 9600,
    int dataBits = 8,
    int stopBits = 1,
    int parity = 0,
  }) async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      dynamic port = _knownPorts[portName];

      if (port == null) {
        try {
          final nav = html.window.navigator;
          final serial = js_util.getProperty(nav, 'serial');
          final portPromise = js_util.callMethod(serial, 'requestPort', []);
          port = await js_util.promiseToFuture(portPromise);

          if (port != null) {
            final name = "WebPort-${_knownPorts.length}";
            _knownPorts[name] = port;
          }
        } catch (e) {
          print('User cancelled or error requesting port: $e');
          return false;
        }
      }

      if (port == null) return false;

      // Create options object
      final options = js_util.newObject();
      js_util.setProperty(options, 'baudRate', baudRate);
      js_util.setProperty(options, 'dataBits', dataBits);
      js_util.setProperty(options, 'stopBits', stopBits);
      js_util.setProperty(options, 'parity', _mapParity(parity));

      final openPromise = js_util.callMethod(port, 'open', [options]);
      await js_util.promiseToFuture(openPromise);

      _port = port;
      _startReading();

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (e) {
      print('Error connecting: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  String _mapParity(int parity) {
    switch (parity) {
      case 1:
        return 'odd';
      case 2:
        return 'even';
      default:
        return 'none';
    }
  }

  void _startReading() async {
    if (_port == null) return;

    try {
      final readable = js_util.getProperty(_port, 'readable');
      if (readable == null) return;

      _reader = js_util.callMethod(readable, 'getReader', []);

      while (true) {
        final readPromise = js_util.callMethod(_reader, 'read', []);
        final result = await js_util.promiseToFuture(readPromise);

        final done = js_util.getProperty(result, 'done');
        final value = js_util.getProperty(result, 'value');

        if (done == true) {
          break;
        }

        if (value != null) {
          // value is a Uint8List (or JS Uint8Array)
          // We might need to cast or convert
          if (value is Uint8List) {
            _dataController.add(value);
          } else if (value is List) {
            _dataController.add(List<int>.from(value));
          } else {
            // Try to convert JS TypedArray to Dart Uint8List
            // Usually Dart handles this automatically for Uint8Array
            try {
              _dataController.add(value as Uint8List);
            } catch (e) {
              print('Error converting data: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error reading: $e');
      disconnect();
    } finally {
      if (_reader != null) {
        try {
          js_util.callMethod(_reader, 'releaseLock', []);
        } catch (e) {
          /* ignore */
        }
      }
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      if (_reader != null) {
        try {
          await js_util.promiseToFuture(
            js_util.callMethod(_reader, 'cancel', []),
          );
          js_util.callMethod(_reader, 'releaseLock', []);
        } catch (e) {
          // Ignore errors if already closed
        }
        _reader = null;
      }

      if (_port != null) {
        await js_util.promiseToFuture(js_util.callMethod(_port, 'close', []));
        _port = null;
      }

      _isConnected = false;
      _connectionController.add(false);
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  @override
  Future<void> send(List<int> data) async {
    if (!_isConnected || _port == null) {
      throw Exception('Port not connected');
    }

    try {
      final writable = js_util.getProperty(_port, 'writable');
      if (writable == null) throw Exception('Port not writable');

      final writer = js_util.callMethod(writable, 'getWriter', []);
      _writer = writer;

      final uint8Data = Uint8List.fromList(data);
      final writePromise = js_util.callMethod(writer, 'write', [uint8Data]);
      await js_util.promiseToFuture(writePromise);

      js_util.callMethod(writer, 'releaseLock', []);
      _writer = null;
    } catch (e) {
      // Release lock if failed
      if (_writer != null) {
        try {
          js_util.callMethod(_writer, 'releaseLock', []);
        } catch (_) {}
        _writer = null;
      }
      throw Exception('Failed to send data: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    _dataController.close();
    _connectionController.close();
  }
}
