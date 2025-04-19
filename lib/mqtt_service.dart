import 'dart:io';
import 'models.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'log_service.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();
  final MyLogService _logService = MyLogService();
  final List<String> _savedTopics = [];
  final List<String> _savedQosLevels = [];
  final TextEditingController serverController = TextEditingController();
  final TextEditingController clientIdController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController certFileController = TextEditingController();
  dynamic receiveMessage;

  Future<void> saveConnectionConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server', serverController.text);
    await prefs.setString('clientId', clientIdController.text);
    await prefs.setString('port', portController.text);
    await prefs.setString('username', usernameController.text);
    await prefs.setString('password', passwordController.text);
    final path = await _localPath;
    await prefs.setString('certFile', '$path/ca.crt');
  }

  Future<void> loadConnectionConfig() async {
    final prefs = await SharedPreferences.getInstance();
    serverController.text =
        prefs.getString('server') ?? 'example.mqtt.com';
    clientIdController.text = prefs.getString('clientId') ?? 'mqtt_client';
    portController.text = prefs.getString('port') ?? '8883';
    usernameController.text = prefs.getString('username') ?? 'client';
    passwordController.text =
        prefs.getString('password') ?? r'';
    certFileController.text = prefs.getString('certFile') ?? '';
  }

  Future<void> saveSubscriptions(
    List<String> topics,
    List<String> qosLevels,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('topics', topics);
    await prefs.setStringList('qosLevels', qosLevels);
  }

  Future<void> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    _savedTopics.clear();
    _savedQosLevels.clear();
    _savedTopics.addAll(prefs.getStringList('topics') ?? []);
    _savedQosLevels.addAll(prefs.getStringList('qosLevels') ?? []);
  }

  List<String> get savedTopics => List.from(_savedTopics);
  List<String> get savedQosLevels => List.from(_savedQosLevels);

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server');
    await prefs.remove('clientId');
    await prefs.remove('port');
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('certFile');
    await prefs.remove('topics');
    await prefs.remove('qosLevels');
    serverController.clear();
    clientIdController.clear();
    portController.clear();
    usernameController.clear();
    passwordController.clear();
    certFileController.clear();
    _savedTopics.clear();
    _savedQosLevels.clear();
  }

  MqttServerClient? _client;
  bool _isConnected = false;
  final NotificationService _notificationService = NotificationService();

  bool get isConnected => _isConnected;

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<File> get _localCertFile async {
    final path = await _localPath;
    return File('$path/ca.crt');
  }

  Future<void> connect() async {
    if (_client != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      return;
    }

    final client = MqttServerClient(
      serverController.text,
      clientIdController.text,
    );
    client.port = int.parse(portController.text);
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    await _notificationService.initialize();
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientIdController.text)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain()
        .authenticateAs(usernameController.text, passwordController.text);

    client.connectionMessage = connMessage;

    try {
      // 检查证书文件路径是否在程序目录内
      final appDir = await getApplicationSupportDirectory();
      final filePath = certFileController.text;
      if (!filePath.startsWith(appDir.path)) {
        await _saveCertificateFromFile(filePath);
      }
      await saveConnectionConfig();
      final certFile = await _localCertFile;
      if (await certFile.exists()) {
        final context = SecurityContext.defaultContext;
        context.setTrustedCertificates(certFile.path);
        client.secure = true;
        client.securityContext = context;
      }

      await client.connect();
      client.subscribe("sys", MqttQos.exactlyOnce);

      // 重新订阅保存的主题
      for (int i = 0; i < _savedTopics.length; i++) {
        final topic = _savedTopics[i];
        final qosLevel = _savedQosLevels[i];
        final qos =
            qosLevel == 'Qos 0'
                ? MqttQos.atMostOnce
                : qosLevel == 'Qos 1'
                ? MqttQos.atLeastOnce
                : MqttQos.exactlyOnce;
        client.subscribe(topic, qos);
      }

      client.updates?.listen(_onMessage);
      _client = client;
    } catch (e) {
      _logService.info('MQTT连接异常: $e');
      client.disconnect();
    }
  }

  void _onConnected() {
    _isConnected = true;
    _logService.info('MQTT连接成功');
  }

  void _onDisconnected() {
    _isConnected = false;
    _logService.info('MQTT连接断开');
  }

  void _onSubscribed(String topic) {
    _logService.info('订阅主题成功: $topic');
  }

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }

  void subscribe(String topic, MqttQos qos) {
    if (_client != null && _isConnected) {
      _client!.subscribe(topic, qos);
    }
  }

  Future<void> _onMessage(
    List<MqttReceivedMessage<MqttMessage>> messages,
  ) async {
    for (var message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      var payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      if(message.topic=="message"){
        try {
          payload=Uri.decodeFull(payload);
          payload=payload.split('\n')[1];
        } catch (e) {
          MyLogService().error('提取验证码失败: $e');
        }
      }

      // 检查并提取验证码
      var content=payload;
      final verificationCode = RegExp(r'\b\d{4,6}\b').firstMatch(payload)?.group(0);
      if (verificationCode != null) {
        content=verificationCode;
        _logService.info('提取到验证码: $verificationCode');
      }

      _notificationService.showNotification(
        title: '主题: ${message.topic}',
        body: payload,
      );
      final mm = MessageModel(message.topic, payload.toString());
      receiveMessage?.call(mm);
      await Clipboard.setData(ClipboardData(text: content));
    }
  }

  void unsubscribe(String topic) {
    if (_client != null && _isConnected) {
      _client!.unsubscribe(topic);
    }
  }

  Future<void> _saveCertificateFromFile(String filePath) async {
    certFileController.text = filePath;
    final sourceFile = File(filePath);
    if (!await sourceFile.exists()) {
      throw Exception('证书文件不存在');
    }
    final certContent = await sourceFile.readAsString();
    final file = await _localCertFile;
    await file.writeAsString(certContent);
  }
}
