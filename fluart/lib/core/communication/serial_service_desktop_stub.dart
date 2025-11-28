import 'dart:async';
import 'serial_service.dart';

class SerialServiceDesktop implements SerialService {
  @override
  Future<bool> connect(
    String portName, {
    int baudRate = 9600,
    int dataBits = 8,
    int stopBits = 1,
    int parity = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<bool> get connectionStatusStream => throw UnimplementedError();

  @override
  Stream<List<int>> get dataStream => throw UnimplementedError();

  @override
  Future<void> disconnect() {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getAvailablePorts() {
    throw UnimplementedError();
  }

  @override
  bool get isConnected => throw UnimplementedError();

  @override
  Future<void> send(List<int> data) {
    throw UnimplementedError();
  }
}
