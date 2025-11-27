import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/serial_provider.dart';
import '../widgets/glass_container.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _settingsExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SerialProvider>();

    // Auto-scroll when logs update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050510), Color(0xFF101025)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Pill (Glowing Status)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050510).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered text
                      Center(
                        child: Text(
                          provider.isConnected
                              ? 'Connected: ${provider.baudRate} 8N1'
                              : 'Disconnected',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Color(0xFF00E5FF), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                      // Settings icon positioned on the right
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Color(0xFF00E5FF),
                            size: 20,
                          ),
                          onPressed: provider.isConnected
                              ? null
                              : () {
                                  setState(() {
                                    _settingsExpanded = !_settingsExpanded;
                                  });
                                },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.5, end: 0),

              // Expandable Settings Panel
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: _settingsExpanded
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050510).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Serial Port Settings',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF00E5FF),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _settingsExpanded = false;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _SettingRow(
                                label: 'Port',
                                child: DropdownButton<String>(
                                  value: provider.selectedPort.isEmpty
                                      ? null
                                      : provider.selectedPort,
                                  hint: const Text(
                                    'Select Port',
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                  dropdownColor: const Color(0xFF12122A),
                                  style: const TextStyle(color: Colors.white),
                                  items: provider.availablePorts
                                      .map(
                                        (port) => DropdownMenuItem(
                                          value: port,
                                          child: Text(port),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: provider.isConnected
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            provider.setPort(value);
                                          }
                                        },
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SettingRow(
                                label: 'Baud Rate',
                                child: DropdownButton<int>(
                                  value: provider.baudRate,
                                  dropdownColor: const Color(0xFF12122A),
                                  style: const TextStyle(color: Colors.white),
                                  items: [9600, 19200, 38400, 57600, 115200]
                                      .map(
                                        (rate) => DropdownMenuItem(
                                          value: rate,
                                          child: Text('$rate'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: provider.isConnected
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            provider.setBaudRate(value);
                                          }
                                        },
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await provider.refreshPorts();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E5FF),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Refresh Ports'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Log Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassContainer(
                    opacity: 0.05,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: provider.logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            provider.logs[index],
                            style: const TextStyle(
                              fontFamily: 'Courier New',
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Control Deck
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  opacity: 0.15,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Enter command...',
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CircularButton(
                            label: provider.isConnected
                                ? 'DISCONNECT'
                                : 'CONNECT',
                            color: const Color(0xFFD500F9),
                            onTap: () {
                              if (provider.isConnected) {
                                provider.disconnect();
                              } else {
                                provider.connect();
                              }
                            },
                          ),
                          _CircularButton(
                            label: 'SEND',
                            color: const Color(0xFF00E5FF),
                            onTap: () {
                              if (_controller.text.isNotEmpty) {
                                provider.send(_controller.text);
                                _controller.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.5, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        child,
      ],
    );
  }
}

class _CircularButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _CircularButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  State<_CircularButton> createState() => _CircularButtonState();
}

class _CircularButtonState extends State<_CircularButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.1),
            border: Border.all(color: widget.color.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: widget.color.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
