import 'dart:async';
import 'dart:convert';

enum ParserMode {
  text, // Parse as UTF-8 text
  hex, // Parse as hex bytes
  newline, // Split by newline
  fixedLength, // Fixed length frames
}

class ProtocolParser {
  final ParserMode mode;
  final int? fixedLength;
  final String delimiter;

  final StreamController<String> _parsedDataController =
      StreamController<String>.broadcast();
  String _buffer = '';
  List<int> _byteBuffer = [];

  ProtocolParser({
    this.mode = ParserMode.newline,
    this.fixedLength,
    this.delimiter = '\n',
  });

  Stream<String> get parsedStream => _parsedDataController.stream;

  void parse(List<int> data) {
    switch (mode) {
      case ParserMode.text:
      case ParserMode.newline:
        _parseText(data);
        break;
      case ParserMode.hex:
        _parseHex(data);
        break;
      case ParserMode.fixedLength:
        _parseFixedLength(data);
        break;
    }
  }

  void _parseText(List<int> data) {
    try {
      final decoded = utf8.decode(data, allowMalformed: true);
      _buffer += decoded;

      if (mode == ParserMode.newline) {
        // Split by delimiter
        final lines = _buffer.split(delimiter);

        // Keep the last incomplete line in buffer
        _buffer = lines.removeLast();

        // Emit complete lines
        for (final line in lines) {
          if (line.isNotEmpty) {
            _parsedDataController.add(line);
          }
        }
      } else {
        // Emit immediately for text mode
        _parsedDataController.add(decoded);
      }
    } catch (e) {
      // Fallback to hex if UTF-8 decoding fails
      _parseHex(data);
    }
  }

  void _parseHex(List<int> data) {
    final hex = data
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    _parsedDataController.add(hex);
  }

  void _parseFixedLength(List<int> data) {
    if (fixedLength == null || fixedLength! <= 0) {
      _parseText(data);
      return;
    }

    _byteBuffer.addAll(data);

    while (_byteBuffer.length >= fixedLength!) {
      final frame = _byteBuffer.sublist(0, fixedLength!);
      _byteBuffer = _byteBuffer.sublist(fixedLength!);

      try {
        final decoded = utf8.decode(frame, allowMalformed: true);
        _parsedDataController.add(decoded);
      } catch (e) {
        _parseHex(frame);
      }
    }
  }

  void clear() {
    _buffer = '';
    _byteBuffer.clear();
  }

  void dispose() {
    _parsedDataController.close();
  }
}
