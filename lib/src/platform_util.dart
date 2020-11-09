import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> exec(String cmd) async {
  String value = '';
  final ProcessResult result = await Process.run(
    'sh',
    ['-c', cmd],
    environment: PlatformUtil.environment(),
  );
  value += result.stdout.toString();
  value += result.stderr.toString();
  return value.trim();
}

bool isAddress(String content) {
  final RegExp regExp = RegExp(
      '((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})(\\.((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})){3}');
  return regExp.hasMatch(content);
}

// 针对平台
class PlatformUtil {
  // 判断当前的设备是否是移动设备
  static String _documentDir;
  static String _packageName;
  static bool isMobilePhone() {
    return Platform.isAndroid || Platform.isIOS;
  }

  // 判断当前的设备是否是桌面设备
  static bool isDesktop() {
    return !isMobilePhone();
  }

  static String getFileName(String filePath) {
    return filePath.split(Platform.pathSeparator).last;
  }

  static String getRealPath(String filePath) {
    if (Platform.isWindows)
      return filePath.replaceAll('/', '\\').replaceAll(RegExp('/c'), 'C:');
    else
      return filePath;
  }

  static String getDownloadPath() {
    if (Platform.isAndroid) {
      return '/sdcard/download';
    }
    final Map<String, String> map = Map.from(Platform.environment);
    print(map);
    return map['HOME'] + '/downloads';
  }

  // 获取二进制文件的路径
  static String getBinaryPath() {
    final Map<String, String> map = Map.from(Platform.environment);
    // print();
    return map['HOME'] + '/downloads';
  }

  // 获取files文件夹的路径，更多用在安卓
  static String getFilsePath(String packageName) {
    return '/data/data/$packageName/files';
  }

  static String getUnixPath(String prePath) {
    if (!RegExp('^[A-Z]:').hasMatch(prePath)) {
      return prePath.replaceAll('\\', '/');
    }
    final Iterable<Match> e = RegExp('^[A-Z]').allMatches(prePath);
    final String patch = e.elementAt(0).group(0);
    return prePath
        .replaceAll('\\', '/')
        .replaceAll(RegExp('^' + patch + ':'), '/' + patch.toLowerCase());
  }

  static Map<String, String> environment() {
    final Map<String, String> map = Map.from(Platform.environment);
    if (Platform.isAndroid) {
      // 只有安卓需要
      map['PATH'] = '/data/data/com.nightmare.adbtool/files:' + map['PATH'];
    }
    return map;
  }

  static Future<bool> cmdIsExist(String cmd) async {
    final String adbPath = await exec('which $cmd');
    await Future<void>.delayed(const Duration(seconds: 1));
    print('adbPath====$adbPath');
    return adbPath.isNotEmpty;
  }

  static Future<String> get documentsDir => () async {
        _documentDir ??= await workDirectory();
        return _documentDir;
      }();
  static Future<String> getPackageName() async {
    if (_packageName == null) {
      Directory appDocumentsDir = await getApplicationSupportDirectory();
      _packageName = appDocumentsDir.path;
      _packageName = _packageName.replaceAll('/data/user/0/', '');
      _packageName = _packageName.replaceAll('/files', '');
    }
    return _packageName;
  }

  static Future<String> get packageName => getPackageName();
  static Future<String> workDirectory() async {
    // 获取外部储存路径的函数
    // 原path_provider中有提供，后来被删除了
    String path;
    if (Platform.isAndroid) {
      Directory storageDirectory = await getExternalStorageDirectory();
      path = storageDirectory.path
          .replaceAll(RegExp('/Android.*'), ''); //初始化外部储存的路径
    } else if (isDesktop()) {
      path = FileSystemEntity.parentOf(Platform.resolvedExecutable);
    }
    return path;
  }
}
