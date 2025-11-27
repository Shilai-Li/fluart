import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/communication/serial_service.dart';
import '../core/communication/serial_service_factory.dart';
import '../core/protocol/protocol_parser.dart';

class SerialProvider extends ChangeNotifier {
  final SerialService _serialService = SerialServiceFactory.create();
  final ProtocolParser _parser = ProtocolParser(mode: ParserMode.newline);

  bool _isConnected = false;
  final List<String> _logs = [];
  List<String> _availablePorts = [];
  String _selectedPort = '';
  int _baudRate = 9600;
  int _dataBits = 8;
  int _stopBits = 1;
  int _parity = 0; // 0 = none, 1 = odd, 2 = even

  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _parsedDataSubscription;

  SerialProvider() {
    _initialize();
  }

  void _initialize() {
    // Listen to connection status
    _connectionSubscription = _serialService.connectionStatusStream.listen((
      connected,
    ) {
      _isConnected = connected;
      notifyListeners();
    });

    // Listen to raw data
    _dataSubscription = _serialService.dataStream.listen((data) {
      _parser.parse(data);
    });

    // Listen to parsed data
    _parsedDataSubscription = _parser.parsedStream.listen((message) {
      addLog('RX: $message');
    });

    // Load available ports
    refreshPorts();
  }

  bool get isConnected => _isConnected;
  List<String> get logs => _logs;
  List<String> get availablePorts => _availablePorts;
  String get selectedPort => _selectedPort;
  int get baudRate => _baudRate;
  int get dataBits => _dataBits;
  int get stopBits => _stopBits;
  int get parity => _parity;

  Future<void> refreshPorts() async {
    _availablePorts = await _serialService.getAvailablePorts();
    if (_availablePorts.isNotEmpty && _selectedPort.isEmpty) {
      _selectedPort = _availablePorts.first;
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (_selectedPort.isEmpty) {
      addLog('Error: No port selected');
      return;
    }

    addLog('Connecting to $_selectedPort at $_baudRate baud...');

    final success = await _serialService.connect(
      _selectedPort,
      baudRate: _baudRate,
      dataBits: _dataBits,
      stopBits: _stopBits,
      parity: _parity,
    );

    if (success) {
      addLog('Connected successfully');
    } else {
      addLog('Failed to connect');
    }
  }

  Future<void> disconnect() async {
    addLog('Disconnecting...');
    await _serialService.disconnect();
    addLog('Disconnected');
  }

  Future<void> send(String message) async {
    if (!_isConnected) {
      addLog('Error: Not connected');
      return;
    }

    try {
      // Add newline for text mode
      final data = utf8.encode('$message\n');
      await _serialService.send(data);
      addLog('TX: $message');
    } catch (e) {
      addLog('Error sending: $e');
    }
  }

  void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logs.add('[$timestamp] $message');

    // Limit log size
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }

    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _parser.clear();
    notifyListeners();
  }

  void setPort(String port) {
    if (!_isConnected) {
      _selectedPort = port;
      notifyListeners();
    }
  }

  void setBaudRate(int rate) {
    if (!_isConnected) {
      _baudRate = rate;
      notifyListeners();
    }
  }

  void setDataBits(int bits) {
    if (!_isConnected) {
      _dataBits = bits;
      notifyListeners();
    }
  }

  void setStopBits(int bits) {
    if (!_isConnected) {
      _stopBits = bits;
      notifyListeners();
    }
  }

  void setParity(int parity) {
    if (!_isConnected) {
      _parity = parity;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _parsedDataSubscription?.cancel();
    _serialService.dispose();
    _parser.dispose();
    super.dispose();
  }
}
