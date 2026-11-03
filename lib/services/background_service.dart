import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';


bool _isProcessingAlert = false;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'safety_service',
    'Safety Monitor',
    description: 'Monitoring for falls and distress.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,

      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'safety_service',
      initialNotificationTitle: 'AI Protection Active',
      initialNotificationContent: 'Monitoring sensors in background...',


      foregroundServiceTypes: [AndroidForegroundType.microphone],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((event) => service.stopSelf());


  userAccelerometerEvents.listen((UserAccelerometerEvent event) async {
    double impactForce = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

    if (impactForce > 25 && !_isProcessingAlert) {
      _isProcessingAlert = true;
      service.invoke('alertTriggered', {"type": "FALL_DETECTED"});
      _executeBackgroundEmergency("FALL_DETECTED");

      Timer(const Duration(seconds: 10), () => _isProcessingAlert = false);
    }
  });
}

void _executeBackgroundEmergency(String type) {
  debugPrint("CRITICAL: Background Emergency Triggered: $type");
}