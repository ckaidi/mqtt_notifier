import 'package:logger/logger.dart';

import 'log_service.dart';
import 'models.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter/cupertino.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final MyLogService _logService = MyLogService();
  final List<LogModel> logs = [];

  _LogsPageState() {
    for (var log in _logService.logs) {
      logs.insert(0,log);
    }
    _logService.infoCallBack=(model){
      setState(() {
        logs.insert(0,LogModel(LogType.info, model));
      });
    };
    _logService.errorCallBack=(model){
      setState(() {
        logs.insert(0,LogModel(LogType.error, model));
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
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final model = logs[index];
                        final topic = model.type == LogType.info ? '信息' : '错误';
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(left: 20.0, right: 16.0, top: 8.0, bottom: 8.0),
                            child: MacosListTile(
                              leading:model.type==LogType.info? const Icon(CupertinoIcons.info):const Icon(CupertinoIcons.bubble_left),
                              title: Text(
                                topic,
                                style: MacosTheme.of(context).typography.headline,
                              ),
                              subtitle: Text('${model.time} ${model.message}',
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
