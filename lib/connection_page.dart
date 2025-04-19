import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'mqtt_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => ConnectionPageState();
}

class ConnectionPageState extends State<ConnectionPage> {
  final MQTTService _mqttService = MQTTService();
  String popupValue = 'mqtts://';
  String _selectedCertFile='';

  Future<void> _selectCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['crt', 'pem'],
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedCertFile=result.files.single.path!;
      _mqttService.certFileController.text = _selectedCertFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 4,
              ),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Label(text: Text('服务器',style: MacosTheme.of(context).typography.body))),
                  const SizedBox(width: 8),
                  MacosPopupButton<String>(
                    value: popupValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        popupValue = newValue!;
                      });
                    },
                    items:
                        <String>[
                          // 'mqtt://',
                          'mqtts://',
                          // 'ws://',
                          // 'wss://',
                        ].map<MacosPopupMenuItem<String>>((String value) {
                          return MacosPopupMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MacosTextField(
                      controller: _mqttService.serverController,
                      placeholder: '输入服务器地址',
                      showCursor: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Label(text: Text('客户端id',style: MacosTheme.of(context).typography.body))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MacosTextField(
                      controller: _mqttService.clientIdController,
                      placeholder: '输入客户端id',
                      showCursor: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Label(text: Text('端口',style: MacosTheme.of(context).typography.body))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MacosTextField(
                      controller: _mqttService.portController,
                      placeholder: '输入端口',
                      showCursor: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Label(text: Text('用户',style: MacosTheme.of(context).typography.body))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MacosTextField(
                      controller: _mqttService.usernameController,
                      placeholder: '输入用户名',
                      showCursor: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Label(text: Text('密码',style: MacosTheme.of(context).typography.body))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MacosTextField(
                      controller: _mqttService.passwordController,
                      placeholder: '输入密码',
                      obscureText: true,
                      showCursor: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Label(text: Text('证书',style: MacosTheme.of(context).typography.body))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MacosTextField(
                      controller: _mqttService.certFileController,
                      placeholder: '请选择证书文件',
                    ),
                  ),
                  const SizedBox(width: 8),
                  PushButton(
                    controlSize: ControlSize.regular,
                    onPressed: _selectCertificate,
                    child: Text('选择证书'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
