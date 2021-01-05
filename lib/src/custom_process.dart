import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'platform_util.dart';

// 自实现的Process基于dart:io库中的Process.start

typedef ProcessCallBack = void Function(String output);

class NiProcess {
  NiProcess(this.callback);
  final ProcessCallBack callback;
  static Process _process;
  // 确保异步安全，这是一种极low的方式
  static bool isUseing = false;
  // 包名
  static Process get process => _process;
  static String get shPath => () {
        switch (Platform.operatingSystem) {
          case 'linux':
            return 'sh';
            break;
          case 'macos':
            return 'sh';
            break;
          case 'windows':
            return 'wsl';
            break;
          case 'android':
            return '/system/bin/sh';
            break;
          default:
            return 'sh';
        }
      }();
  static Future<void> ensureInitialized() async {
    if (process == null) {
      await _init();
    }
  }

  static Future<void> _init() async {
    _process = await Process.start(
      shPath,
      <String>[],
      includeParentEnvironment: true,
      runInShell: false,
      environment: PlatformUtil.environment(),
    );
    // 初始化app的环境变量
    // if (Platform.isAndroid) {
    //   isUseing = true;
    //   // _process.stdin.write(
    //   //   'su\n',
    //   // );

    // }

    // processStderr.transform(utf8.decoder).listen((event) {
    //   print('$NiProcess------>$event');
    // });
  }

  static Stream<List<int>> processStdout = _process.stdout.asBroadcastStream();
  static Stream<List<int>> processStderr = _process.stderr.asBroadcastStream();
  // static void exit() {
  //   if (isUseing) {
  //     // _process.stdin.write('echo exitCode\n');
  //   }
  // }

  static Future<String> exec(
    String script, {
    ProcessCallBack callback,
    bool getStdout = true,
    bool getStderr = false,
  }) async {
    // print(isUseing);
    while (isUseing) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    isUseing = true;
    if (_process == null) {
      /// 如果初始为空需要城初始化Process
      await PlatformUtil.init();
      await _init();
    }
    final StringBuffer buffer = StringBuffer();
    if (!script.endsWith('\n')) {
      script += '\n';
    }
    _process.stdin.write(script);
    // print('脚本====>$script');
    _process.stdin.write('echo process_exit\n');
    if (getStderr) {
      print('等待错误');
      processStderr.transform(utf8.decoder).every(
        (String out) {
          // print('processStdout错误输出为======>$out');
          buffer.write(out);
          callback?.call(out);
          return isUseing;
        },
      );
    }
    if (getStdout) {
      await processStdout.transform(utf8.decoder).every(
        (String out) {
          // print('processStdout输出为======>$out');
          buffer.write(out);
          callback?.call(out);
          //
          return !out.contains('process_exit');
        },
      );
    }
    // print('释放锁');
    isUseing = false;
    return buffer.toString().replaceAll('process_exit', '').trim();
  }
}
