import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:jsba_app/app/model/feedback_model.dart';

class DeviceInfoHelper {
  static Future<DeviceInfoModel> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    String model = 'Unknown';
    String osVersion = 'Unknown';
    String appVersion = '1.0.0';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      model = '${androidInfo.manufacturer} ${androidInfo.model}';
      osVersion = 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      model = iosInfo.utsname.machine;
      osVersion = 'iOS ${iosInfo.systemVersion}';
    }

    return DeviceInfoModel(
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
    );
  }
}
