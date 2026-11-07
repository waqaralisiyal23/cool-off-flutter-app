import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;

class LocalUtils {
  LocalUtils._();

  static late final Directory appDirectory;

  static Future<void> init() async {
    appDirectory = await getAppDirectory();
  }

  static Future<Directory> getAppDirectory() async {
    final directory = await path_provider.getApplicationSupportDirectory();
    return directory;
  }
}
