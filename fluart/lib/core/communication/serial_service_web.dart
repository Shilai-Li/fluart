import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'serial_service.dart';

// --- Web Serial API Interop Definitions ---

@JS('navigator.serial')
external Serial? get _serial;

@JS()
extension type Serial._(JSObject _) implements JSObject {
  external JSPromise<JSArray<SerialPort>> getPorts();
  external JSPromise<SerialPort> requestPort([
    SerialPortRequestOptions? options,
  ]);
}

@JS()
@anonymous
extension type SerialPortRequestOptions._(JSObject _) implements JSObject {
  external factory SerialPortRequestOptions({
    JSArray<SerialPortFilter>? filters,
  });
}

@JS()
@anonymous
extension type SerialPortFilter._(JSObject _) implements JSObject {
  external factory SerialPortFilter({int? usbVendorId, int? usbProductId});
}

@JS()
extension type SerialPort._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> open(SerialOptions options);
  external JSPromise<JSAny?> close();
  external ReadableStream get readable;
  external WritableStream get writable;
  // We can use a simple way to get info or just use the object identity for the name
}

@JS()
@anonymous
extension type SerialOptions._(JSObject _) implements JSObject {
  external factory SerialOptions({
    required int baudRate,
    int? dataBits,
    int? stopBits,
    String? parity,
    int? bufferSize,
    String? flowControl,
  });
}

@JS()
extension type ReadableStream._(JSObject _) implements JSObject {
  external ReadableStreamDefaultReader getReader();
  external bool get locked;
}

@JS()
extension type ReadableStreamDefaultReader._(JSObject _) implements JSObject {
  external JSPromise<ReadableStreamReadResult> read();
  external void releaseLock();
  external JSPromise<JSAny?> cancel([JSAny? reason]);
}

@JS()
extension type ReadableStreamReadResult._(JSObject _) implements JSObject {
  external JSAny? get value;
  external bool get done;
}

@JS()
extension type WritableStream._(JSObject _) implements JSObject {
  external WritableStreamDefaultWriter getWriter();
  external bool get locked;
}

@JS()
extension type WritableStreamDefaultWriter._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSAny? chunk);
  external void releaseLock();
  external JSPromise<JSAny?> close();
  external JSPromise<JSAny?> abort([JSAny? reason]);
}

// --- Implementation ---

class SerialServiceWeb implements SerialService {
  SerialPort? _port;
  ReadableStreamDefaultReader? _reader;
  WritableStreamDefaultWriter? _writer;

  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;

  // Map to store port objects.
  // In the new interop, we can keep the SerialPort objects directly.
  // We'll assign them arbitrary names for the UI.
  final List<SerialPort> _knownPorts = [];

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  @override
  Future<List<String>> getAvailablePorts() async {
    final serial = _serial;
    if (serial == null) {
      return ['Web Serial API not supported'];
    }

    try {
      final portsJS = await serial.getPorts().toDart;
      final ports = portsJS.toDart;

      _knownPorts.clear();
      _knownPorts.addAll(ports);

      final List<String> portNames = [];
      for (var i = 0; i < _knownPorts.length; i++) {
        portNames.add("WebPort-$i");
      }

      if (portNames.isEmpty) {
        return ['Select Port...'];
      }

      return portNames;
    } catch (e) {
      // ignore: avoid_print
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

      SerialPort? port;

      // Check if it's a known port
      if (portName.startsWith("WebPort-")) {
        final indexStr = portName.substring("WebPort-".length);
        final index = int.tryParse(indexStr);
        if (index != null && index >= 0 && index < _knownPorts.length) {
          port = _knownPorts[index];
        }
      }

      // If not found or user wants to select a new one (implied by "Select Port..." logic usually,
      // but here we handle the case where we might need to request permission)
      if (port == null) {
        try {
          final serial = _serial;
          if (serial != null) {
            port = await serial.requestPort().toDart;
            _knownPorts.add(port);
          }
        } catch (e) {
          // ignore: avoid_print
          print('User cancelled or error requesting port: $e');
          return false;
        }
      }

      if (port == null) return false;

      final options = SerialOptions(
        baudRate: baudRate,
        dataBits: dataBits,
        stopBits: stopBits,
        parity: _mapParity(parity),
      );

      await port.open(options).toDart;

      _port = port;
      _startReading();

      _isConnected = true;
      _connectionController.add(true);
      return true;
    } catch (e) {
      // ignore: avoid_print
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
      // Check if readable is available
      // Note: In strict interop, we might need to check if properties exist,
      // but the extension type assumes it matches the IDL.
      final readable = _port!.readable;
      // if (readable == null) return; // ReadableStream is usually always there if open succeeded

      _reader = readable.getReader();

      while (true) {
        final result = await _reader!.read().toDart;
        final done = result.done;
        final value = result.value;

        if (done) {
          break;
        }

        if (value != null) {
          // value is usually a Uint8Array
          final uint8Array = value as JSUint8Array;
          _dataController.add(uint8Array.toDart);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error reading: $e');
      disconnect();
    } finally {
      if (_reader != null) {
        try {
          _reader!.releaseLock();
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
          await _reader!.cancel().toDart;
          _reader!.releaseLock();
        } catch (e) {
          // Ignore errors if already closed
        }
        _reader = null;
      }

      if (_writer != null) {
        try {
          await _writer!.close().toDart;
          _writer!.releaseLock();
        } catch (e) {
          // Ignore
        }
        _writer = null;
      }

      if (_port != null) {
        await _port!.close().toDart;
        _port = null;
      }

      _isConnected = false;
      _connectionController.add(false);
    } catch (e) {
      // ignore: avoid_print
      print('Error disconnecting: $e');
    }
  }

  @override
  Future<void> send(List<int> data) async {
    if (!_isConnected || _port == null) {
      throw Exception('Port not connected');
    }

    try {
      final writable = _port!.writable;
      // if (writable == null) throw Exception('Port not writable');

      final writer = writable.getWriter();
      _writer = writer;

      final uint8Data = Uint8List.fromList(data).toJS;
      await writer.write(uint8Data).toDart;

      writer.releaseLock();
      _writer = null;
    } catch (e) {
      // Release lock if failed
      if (_writer != null) {
        try {
          _writer!.releaseLock();
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
