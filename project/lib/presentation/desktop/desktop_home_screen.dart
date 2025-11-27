import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/serial_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class DesktopHomeScreen extends StatelessWidget {
  const DesktopHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SerialProvider>();
    final TextEditingController _controller = TextEditingController();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF101025), Color(0xFF050510)],
          ),
        ),
        child: Row(
          children: [
            // Sidebar
            GlassContainer(
              width: 250,
              margin: const EdgeInsets.all(16),
              opacity: 0.08,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONFIGURATION',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    'PORT',
                    provider.selectedPort,
                    provider.availablePorts,
                    (val) => provider.setPort(val!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    'BAUD RATE',
                    provider.baudRate.toString(),
                    ['9600', '115200', '57600'],
                    (val) => provider.setBaudRate(int.parse(val!)),
                  ),
                  const Spacer(),
                  // Connect Button
                  GestureDetector(
                    onTap: () {
                      if (provider.isConnected) {
                        provider.disconnect();
                      } else {
                        provider.connect();
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: AppTheme.neonDecoration(
                        color: provider.isConnected
                            ? Colors.redAccent
                            : const Color(0xFF00E5FF),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        provider.isConnected ? 'DISCONNECT' : 'CONNECT',
                        style: TextStyle(
                          color: provider.isConnected
                              ? Colors.redAccent
                              : const Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                ],
              ),
            ).animate().slideX(begin: -0.2, end: 0),

            // Main Area
            Expanded(
              child: Column(
                children: [
                  // Log Area
                  Expanded(
                    flex: 3,
                    child: GlassContainer(
                      margin: const EdgeInsets.only(
                        top: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      opacity: 0.05,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TERMINAL OUTPUT',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () => provider.clearLogs(),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: provider.logs.length,
                              itemBuilder: (context, index) {
                                return Text(
                                  provider.logs[index],
                                  style: const TextStyle(
                                    fontFamily: 'Courier New',
                                    color: Color(0xFF00E5FF),
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Command Area
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GlassContainer(
                            margin: const EdgeInsets.only(right: 8, bottom: 16),
                            opacity: 0.1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COMMAND INJECTION',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Courier New',
                                        ),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Enter hex or ascii command...',
                                          border: InputBorder.none,
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
                              ],
                            ),
                          ),
                        ),
                        // Inspector / Quick Actions
                        Expanded(
                          flex: 1,
                          child: GlassContainer(
                            margin: const EdgeInsets.only(
                              right: 16,
                              bottom: 16,
                            ),
                            opacity: 0.08,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'INSPECTOR',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildInspectorRow('RX Bytes', '1024'),
                                _buildInspectorRow('TX Bytes', '512'),
                                _buildInspectorRow('Errors', '0'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white30, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF12122A),
              style: const TextStyle(color: Colors.white),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectorRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontFamily: 'Courier New',
            ),
          ),
        ],
      ),
    );
  }
}
