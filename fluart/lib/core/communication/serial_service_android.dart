import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'serial_service.dart';

class SerialServiceAndroid implements SerialService {
  UsbPort? _port;
  UsbDevice? _device;

  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;
  StreamSubscription? _subscription;

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  @override
  Future<List<String>> getAvailablePorts() async {
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      return devices.map((device) {
        return '${device.manufacturerName ?? "Unknown"} ${device.productName ?? "Device"} (VID:${device.vid} PID:${device.pid})';
      }).toList();
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

      // Get list of devices
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        return false;
      }

      // Find device by port name (using index or device info)
      // For simplicity, use the first device
      _device = devices.first;

      // Create port
      _port = await UsbSerial.createFromDeviceId(_device!.deviceId);
      if (_port == null) {
        return false;
      }

      // Open port
      bool openResult = await _port!.open();
      if (!openResult) {
        return false;
      }

      // Configure port
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(baudRate, dataBits, stopBits, parity);

      // Listen for data
      _subscription = _port!.inputStream?.listen(
        (Uint8List data) {
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
      await _subscription?.cancel();
      _subscription = null;

      await _port?.close();
      _port = null;
      _device = null;

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
      await _port!.write(Uint8List.fromList(data));
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
