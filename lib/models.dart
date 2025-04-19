import 'package:logger/logger.dart';

class MessageModel{
  String topic;
  String message;
  DateTime time=DateTime.now();

  MessageModel(this.topic,this.message);
}

enum LogType{
  info,
  error
}

class LogModel{
  LogType type;  
  String message;
  String time=DateTimeFormat.dateAndTime(DateTime.now());

  LogModel(this.type,this.message);
}