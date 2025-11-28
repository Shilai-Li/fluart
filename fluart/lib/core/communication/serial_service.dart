/// Abstract interface for Serial Port communication.
/// This allows for easy swapping of implementations (e.g., mock vs real, or different libraries).
abstract class SerialService {
  /// Get a list of available serial ports.
  Future<List<String>> getAvailablePorts();

  /// Connect to a specific port with given configuration.
  Future<bool> connect(
    String portName, {
    int baudRate = 9600,
    int dataBits = 8,
    int stopBits = 1,
    int parity = 0,
  });

  /// Disconnect from the current port.
  Future<void> disconnect();

  /// Send data to the connected port.
  Future<void> send(List<int> data);

  /// Stream of incoming data.
  Stream<List<int>> get dataStream;

  /// Stream of connection status changes.
  Stream<bool> get connectionStatusStream;

  /// Check if currently connected.
  bool get isConnected;

  /// Dispose resources
  void dispose();
}
