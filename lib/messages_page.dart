import 'models.dart';
import 'package:macos_ui/macos_ui.dart';
import 'mqtt_service.dart';
import 'package:flutter/cupertino.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final MQTTService _mqttService = MQTTService();
  final List<MessageModel> receiveMessages = [];

  _MessagesPageState() {
    _mqttService.receiveMessage=(model){
      setState(() {
        receiveMessages.insert(0, model);
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Column(
              children: [
                Expanded(
                  child: MacosScrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: receiveMessages.length,
                      itemBuilder: (context, index) {
                        final model = receiveMessages[index];
                        final topic = model.topic;
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(left: 20.0, right: 16.0, top: 8.0, bottom: 8.0),
                            child: MacosListTile(
                              leading: const Icon(CupertinoIcons.bubble_left),
                              title: Text(
                                '主题：$topic',
                                style: MacosTheme.of(context).typography.headline,
                              ),
                              subtitle: Text(
                                model.message,
                                style: MacosTheme.of(context).typography.subheadline.copyWith(
                                  color: MacosColors.systemGrayColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
