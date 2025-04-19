import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_service.dart';
import 'package:flutter/cupertino.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final TextEditingController _topicController = TextEditingController();
  final List<String> _subscribedTopics = [];
  final List<String> _subscribedTopicsLevels = [];
  final MQTTService _mqttService = MQTTService();
  String popupValue = 'Qos 2';
  final Map<String, MqttQos> _qosMap = {
    'Qos 0': MqttQos.atMostOnce,
    'Qos 1': MqttQos.atLeastOnce,
    'Qos 2': MqttQos.exactlyOnce,
  };

  @override
  void initState() {
    super.initState();
    for (var level in _mqttService.savedQosLevels) {
      _subscribedTopicsLevels.add(level);
    }
    for (var topic in _mqttService.savedTopics) {
      _subscribedTopics.add(topic);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _addSubscription() {
    final topic = _topicController.text.trim();
    if (topic.isNotEmpty && !_subscribedTopics.contains(topic)) {
      _mqttService.subscribe(topic, _qosMap[popupValue]!);
      setState(() {
        _subscribedTopics.insert(0, topic);
        _subscribedTopicsLevels.insert(0, popupValue);
      });
      _mqttService.saveSubscriptions(
        _subscribedTopics,
        _subscribedTopicsLevels,
      );
      _topicController.clear();
    }
  }

  void _removeSubscription(String topic) {
    _mqttService.unsubscribe(topic);
    setState(() {
      final index = _subscribedTopics.indexOf(topic);
      _subscribedTopics.remove(topic);
      _subscribedTopicsLevels.removeAt(index);
    });
    _mqttService.saveSubscriptions(_subscribedTopics, _subscribedTopicsLevels);
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 4.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: MacosTextField(
                          controller: _topicController,
                          placeholder: '输入订阅主题',
                        ),
                      ),
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
                              'Qos 0',
                              'Qos 1',
                              'Qos 2',
                            ].map<MacosPopupMenuItem<String>>((String value) {
                              return MacosPopupMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                      const SizedBox(width: 8),
                      PushButton(
                        controlSize: ControlSize.regular,
                        onPressed: _addSubscription,
                        child: const Text('添加订阅'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MacosScrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _subscribedTopics.length,
                      itemBuilder: (context, index) {
                        final topic = _subscribedTopics[index];
                        final level = _subscribedTopicsLevels[index];
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 20.0,
                              right: 16.0,
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: MacosListTile(
                                    leading: const Icon(
                                      CupertinoIcons.app_badge,
                                    ),
                                    title: Text(
                                      topic,
                                      style:
                                          MacosTheme.of(
                                            context,
                                          ).typography.headline,
                                    ),
                                    subtitle: Text(
                                      level,
                                      style: MacosTheme.of(
                                        context,
                                      ).typography.subheadline.copyWith(
                                        color: MacosColors.systemGrayColor,
                                      ),
                                    ),
                                  ),
                                ),
                                MacosIconButton(
                                  icon: const Icon(
                                    CupertinoIcons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: (){
                                    _removeSubscription(topic);
                                  },
                                ),
                              ],
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
