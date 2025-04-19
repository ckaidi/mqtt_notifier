import 'package:logger/logger.dart';
import 'models.dart';

class MyLogService {
  static final MyLogService _instance = MyLogService._internal();
  factory MyLogService() => _instance;
  MyLogService._internal();
  final List<LogModel> logs = [];

  final Logger logger=Logger();
  Function(String)? infoCallBack=null;
  Function(String)? errorCallBack=null;

  info(message){
    logger.i(message);
    if(infoCallBack==null){
      logs.add(LogModel(LogType.info, message));
    }
    infoCallBack?.call(message);
  }

  error(message){
    logger.i(message);
    if(errorCallBack==null){
      logs.add(LogModel(LogType.error, message));
    }
    errorCallBack?.call(message);
  }
}