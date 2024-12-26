import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'auth_services.dart';
import 'database_services.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> sendNotification(String title, String body) async {

}


Future<void> deleteNotification(
    String notificationId, BuildContext context, VoidCallback onStateUpdate) async {
  try {
    final url = Uri.parse('${getBaseUrl()}/device/notification/$notificationId');
    final headers = await getHeaders();
    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      await _deleteValidationData(notificationId, onStateUpdate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi telah dihapus'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus notifikasi: ${response.statusCode}'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error deleting notification: $e'),
      ),
    );
  }
}

Future<void> _deleteValidationData(
    String notificationId, VoidCallback onStateUpdate) async {
  final db = await DatabaseService().database;
  await db.delete(
    'validation_data',
    where: 'id = ?',
    whereArgs: [notificationId],
  );
  onStateUpdate();
}

Future<void> deleteAllNotifications(BuildContext context, VoidCallback onStateUpdate) async {
  try {
    final url = Uri.parse('${getBaseUrl()}/device/notification');
    final headers = await getHeaders();
    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      final db = await DatabaseService().database;
      await db.delete('validation_data');

      onStateUpdate();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi telah dihapus')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus semua notifikasi: ${response.statusCode}',
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error deleting all notifications: $e'),
      ),
    );
  }
}
