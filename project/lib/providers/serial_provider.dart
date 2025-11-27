import 'dart:async';
import 'package:flutter/material.dart';

class SerialProvider extends ChangeNotifier {
  // Mock implementation for UI development
  bool _isConnected = false;
  final List<String> _logs = [];
  final List<String> _availablePorts = ['COM1', 'COM2', 'COM3'];
  String _selectedPort = 'COM1';
  int _baudRate = 9600;

  bool get isConnected => _isConnected;
  List<String> get logs => _logs;
  List<String> get availablePorts => _availablePorts;
  String get selectedPort => _selectedPort;
  int get baudRate => _baudRate;

  void connect() {
    _isConnected = true;
    addLog('Connected to $_selectedPort at $_baudRate');
    notifyListeners();
  }

  void disconnect() {
    _isConnected = false;
    addLog('Disconnected');
    notifyListeners();
  }

  void send(String message) {
    if (!_isConnected) return;
    addLog('TX: $message');
    // Simulate echo
    Future.delayed(const Duration(milliseconds: 500), () {
      addLog('RX: Echo - $message');
    });
  }

  void addLog(String message) {
    _logs.add(
      '[${DateTime.now().toIso8601String().substring(11, 19)}] $message',
    );
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void setPort(String port) {
    _selectedPort = port;
    notifyListeners();
  }

  void setBaudRate(int rate) {
    _baudRate = rate;
    notifyListeners();
  }
}
