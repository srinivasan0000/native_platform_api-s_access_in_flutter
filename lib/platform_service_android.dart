import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformService {
  static const platform = MethodChannel('platformApi');

  static Future<String> getBatteryLevel() async {
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      return 'Battery level: $result%';
    } on PlatformException catch (e) {
      return "Failed to get battery level: '${e.message}'.";
    }
  }

  static Future<void> showToast(String message) async {
    try {
      await platform.invokeMethod('showToast', {'message': message});
    } on PlatformException catch (e) {
      debugPrint("Failed to show toast: '${e.message}'.");
    }
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await platform.invokeMethod('getDeviceInfo');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      } else {
        debugPrint("Unexpected result type from getDeviceInfo: ${result.runtimeType}");
        return {};
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get device info: '${e.message}'.");
      return {};
    }
  }

  static Future<void> startAccelerometer() async {
    try {
      await platform.invokeMethod('startAccelerometer');
    } on PlatformException catch (e) {
      debugPrint("Failed to start accelerometer: '${e.message}'.");
    }
  }

  static Future<void> stopAccelerometer() async {
    try {
      await platform.invokeMethod('stopAccelerometer');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop accelerometer: '${e.message}'.");
    }
  }

  static Future<void> showNotification(String title, String content) async {
    try {
      await platform.invokeMethod('showNotification', {'title': title, 'content': content});
      debugPrint("Notification method invoked successfully");
    } on PlatformException catch (e) {
      debugPrint("Failed to show notification: '${e.message}'.");
    }
  }

  static void setAccelerometerCallback(Function(double x, double y, double z) callback) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'accelerometerData') {
        final args = call.arguments as Map;
        callback(args['x'], args['y'], args['z']);
      }
    });
  }
}
