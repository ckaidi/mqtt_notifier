import 'dart:io';
import 'package:flutter/foundation.dart';
import 'mqtt_service.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'home_page.dart';
import 'package:window_manager/window_manager.dart';

/// This method initializes macos_window_utils and styles the window.
Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig();
  await config.apply();
}

Future<void> _initSystemTray() async {
  // 替换废弃的 window 属性
  final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  final isDarkMode = brightness == Brightness.dark;
  
  await _updateTrayIcon(isDarkMode);
  
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show',
        label: '显示',
        onClick: (menuItem) => windowManager.show(),
      ),
      MenuItem(
        key: 'hide',
        label: '隐藏',
        onClick: (menuItem) => windowManager.hide(),
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit',
        label: '退出',
        onClick: (menuItem) => windowManager.destroy(),
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}

Future<void> _updateTrayIcon(bool isDarkMode) async {
  await trayManager.setIcon(
    Platform.isMacOS
        ? isDarkMode 
            ? 'assets/logo_w.png'
            : 'assets/logo_b.png'
        : 'assets/app_icon.ico',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await MQTTService().loadConnectionConfig();
  await  MQTTService().loadSubscriptions();
  await MQTTService().connect();
  if (!kIsWeb && Platform.isMacOS) {
    await _configureMacosWindowUtils();
    await _initSystemTray();
  }
  
  runApp(const MacosUIGalleryApp());
}

class MacosUIGalleryApp extends StatelessWidget {
  const MacosUIGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        appTheme.addListener(() {
          _initSystemTray();  // 主题变化时更新托盘图标
        });
        return MacosApp(
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
          });
      },
    );
  }
}

class AppTheme extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  set mode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}