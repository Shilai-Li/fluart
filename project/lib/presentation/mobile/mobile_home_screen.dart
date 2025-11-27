import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/serial_provider.dart';

import '../widgets/glass_container.dart';

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SerialProvider>();
    final TextEditingController _controller = TextEditingController();

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
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
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
              ).animate().fadeIn().slideY(begin: -0.5, end: 0),

              // Log Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassContainer(
                    opacity: 0.05,
                    child: ListView.builder(
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
