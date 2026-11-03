import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestPermissions() async {
    await [
      Permission.locationAlways,
      Permission.microphone,
      Permission.sms,
      Permission.sensors,
    ].request();
  }
}

