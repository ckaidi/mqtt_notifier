import 'package:flutter/material.dart';
import 'package:mqtt_notifier/log_service.dart';
import 'package:mqtt_notifier/logs_page.dart';
import 'connection_page.dart';
import 'messages_page.dart';
import 'package:macos_ui/macos_ui.dart';
import 'subscription_page.dart';
import 'package:flutter/cupertino.dart';
import 'mqtt_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  int _selectedIndex = 0;

  final List<String> _sidebarItems = ['连接','主题', '消息', '日志'];
  final MQTTService _mqttService = MQTTService();

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
    // setState(() {
    //   _showCustomPopup = true;
    // });
    // windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    // do something
  }

  @override
  void onTrayIconRightMouseUp() {
    // do something
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show') {
      await windowManager.show();
    } else if (menuItem.key == 'hide') {
      // 隐藏程序窗口
      await windowManager.hide();
    }else if (menuItem.key == 'exit_app') {
       // do something
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 120,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: _selectedIndex,
            onChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.dot_radiowaves_left_right),
                label: Text(_sidebarItems[0]),
              ),
              SidebarItem(
                leading: MacosIcon(Icons.subscriptions),
                label: Text(_sidebarItems[1]),
              ),
              SidebarItem(
                leading: MacosIcon(Icons.chat_bubble),
                label: Text(_sidebarItems[2]),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.exclamationmark_circle),
                label: Text(_sidebarItems[3]),
              ),
            ],
          );
        },
      ),
      child: MacosScaffold(
        toolBar: ToolBar(
          titleWidth: 200.0,
          title:  Text(_sidebarItems[_selectedIndex]),
          actions: [
            ToolBarIconButton(
              icon: MacosIcon(_mqttService.isConnected ?CupertinoIcons.power:CupertinoIcons.play_fill, color: _mqttService.isConnected ? Colors.red : Colors.green),
              label: '连接',
              showLabel: false,
              tooltipMessage: '连接服务器',
              onPressed: () {
                try {
                  if(_mqttService.isConnected){
                    _mqttService.disconnect();
                  }else{
                    _mqttService.connect();
                  }
                }catch(e){
                  MyLogService().error(e.toString());
                }
              }
            ),
          ]
        ),
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return IndexedStack(
                index: _selectedIndex,
                children: const [
                  ConnectionPage(),
                  SubscriptionPage(),
                  MessagesPage(),
                  LogsPage(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
