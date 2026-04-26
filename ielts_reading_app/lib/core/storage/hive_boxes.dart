import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  HiveBoxes._();

  static const _sessionBoxName = 'speakup_sessions';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_sessionBoxName);
  }

  static Box get session => Hive.box(_sessionBoxName);
}
