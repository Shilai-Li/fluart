import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/layout/responsive_layout.dart';
import 'presentation/mobile/mobile_home_screen.dart';
import 'presentation/desktop/desktop_home_screen.dart';
import 'providers/serial_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SerialProvider())],
      child: MaterialApp(
        title: 'Fluart Serial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ResponsiveLayout(
          mobileScaffold: MobileHomeScreen(),
          desktopScaffold: DesktopHomeScreen(),
        ),
      ),
    );
  }
}
