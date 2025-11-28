import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'serial_service.dart';

class SerialServiceDesktop implements SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;

  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  @override
  Future<List<String>> getAvailablePorts() async {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      return [];
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
      // Disconnect if already connected
      if (_isConnected) {
        await disconnect();
      }

      _port = SerialPort(portName);

      if (!_port!.openReadWrite()) {
        return false;
      }

      // Configure port
      final config = SerialPortConfig();
      config.baudRate = baudRate;
      config.bits = dataBits;
      config.stopBits = stopBits;
      config.parity = parity;
      _port!.config = config;

      // Start reading
      _reader = SerialPortReader(_port!);
      _reader!.stream.listen(
        (data) {
          _dataController.add(data);
        },
        onError: (error) {
          disconnect();
        },
      );

      _isConnected = true;
      _connectionController.add(true);

      return true;
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _reader?.close();
      _reader = null;

      _port?.close();
      _port?.dispose();
      _port = null;

      _isConnected = false;
      _connectionController.add(false);
    } catch (e) {
      // Ignore errors during disconnect
    }
  }

  @override
  Future<void> send(List<int> data) async {
    if (!_isConnected || _port == null) {
      throw Exception('Port not connected');
    }

    try {
      _port!.write(Uint8List.fromList(data));
    } catch (e) {
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
