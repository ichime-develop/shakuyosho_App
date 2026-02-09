import 'package:hive/hive.dart';

const String kAppSettingsBox = 'appSettings';
const String kAppSettingsFlagsKey = 'flags';
const String kFirstLaunchKey = 'isFirstLaunch';

/// 初回起動フラグを取得（未保存なら true）
bool isFirstLaunch() {
  final box = Hive.box<Map>(kAppSettingsBox);
  final raw = box.get(kAppSettingsFlagsKey);
  if (raw is Map && raw[kFirstLaunchKey] is bool) {
    return raw[kFirstLaunchKey] as bool;
  }
  return true;
}

/// 初回起動フラグをオフにする
Future<void> setFirstLaunchDone() async {
  final box = Hive.box<Map>(kAppSettingsBox);
  final raw = box.get(kAppSettingsFlagsKey);
  final updated =
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  updated[kFirstLaunchKey] = false;
  await box.put(kAppSettingsFlagsKey, updated);
}
