import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:imon_app/services/auth_services.dart';
import '../models/validation_data.dart';
import '../utils/debug.dart';
import '../utils/timezone.dart';
import 'monitoring_data_service.dart';
import 'notification_services.dart';

ValueNotifier<bool> shouldNotify = ValueNotifier<bool>(false);
const int interval = 5; // in minutes

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'validation_channel',
    'BATASAN SENSOR',
    description:
    'Sensor mendeteksi bacaan diluar batasan, segera cek halaman notifikasi.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_stat_imon'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: 'validation_channel',
      initialNotificationTitle: 'Batasan Sensor',
      initialNotificationContent: 'Layanan pengecekan bacaan sensor berjalan',
      foregroundServiceNotificationId: 123,
    ),
  );
}

void startService() {
  final service = FlutterBackgroundService();
  service.startService();
}

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  service.on("start").listen((event) {});

  service.on("stop").listen((event) {
    service.stopSelf();
    debugMode("service stopped");
  });

  Timer.periodic(const Duration(minutes: interval), (timer) async {
    if (await checkLoginStatus()) {
      await getAllDeviceMonitorData('${interval}m', getCurrentDateTime());
      await hasValidationData();
      if (!validationNotifier.value) {
        flutterLocalNotificationsPlugin.show(
          123,
          'Peringatan Sensor',
          'Sensor mendeteksi bacaan di luar batasan. Segera cek aplikasi.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'validation_channel',
              'BATASAN SENSOR',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'ic_stat_imon',
              ticker: 'Validation Warning',
            ),
            iOS: DarwinNotificationDetails(
              subtitle: 'Peringatan',
            ),
          ),
        );
      }
    }
  });
}

// Future<void> startBackgroundService() async {
//   final service = FlutterBackgroundService();
//   service.startService();
// }
//
// void stopBackgroundService() {
//   final service = FlutterBackgroundService();
//   service.invoke('stopService');
// }
//
// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();
//
//   await service.configure(
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//     androidConfiguration: AndroidConfiguration(
//       autoStart: false,
//       onStart: onStart,
//       isForegroundMode: false,
//       autoStartOnBoot: false,
//     ),
//   );
//
//   service.startService();
//
// }
//
// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });
//
//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }
//
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//   await getAllDeviceMonitorData(aDayInterval(), getCurrentDateTime());
//
//   Timer.periodic(const Duration(minutes: 1), (timer) async {
//     await getAllDeviceMonitorData("1m", getCurrentDateTime());
//   });
// }
