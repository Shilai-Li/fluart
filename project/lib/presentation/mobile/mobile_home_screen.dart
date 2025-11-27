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
              // Header Pill
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  height: 60,
                  opacity: 0.1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: provider.isConnected
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (provider.isConnected
                                              ? Colors.greenAccent
                                              : Colors.redAccent)
                                          .withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            provider.isConnected
                                ? '${provider.selectedPort} @ ${provider.baudRate}'
                                : 'Disconnected',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {
                          _showSettingsSheet(context);
                        },
                      ),
                    ],
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
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF00E5FF),
                            ),
                            onPressed: () {
                              if (_controller.text.isNotEmpty) {
                                provider.send(_controller.text);
                                _controller.clear();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            label: 'HEX',
                            isActive: false,
                            onTap: () {},
                          ),
                          _ActionButton(
                            label: 'CLEAR',
                            isActive: false,
                            onTap: () => provider.clearLogs(),
                          ),
                          _ActionButton(
                            label: provider.isConnected
                                ? 'DISCONNECT'
                                : 'CONNECT',
                            isActive: true,
                            color: provider.isConnected
                                ? Colors.redAccent
                                : const Color(0xFF00E5FF),
                            onTap: () {
                              if (provider.isConnected) {
                                provider.disconnect();
                              } else {
                                provider.connect();
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

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12122A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Add settings dropdowns here
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (color ?? const Color(0xFF00E5FF)).withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: (color ?? const Color(0xFF00E5FF)).withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (color ?? const Color(0xFF00E5FF)).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color ?? const Color(0xFF00E5FF),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
