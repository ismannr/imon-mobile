import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_services.dart';

ValueNotifier<bool> validationNotifier = ValueNotifier<bool>(false);

class ValidationData {
  final String notificationId;
  final String deviceId;
  final String deviceName;
  final String groupId;
  final String groupName;
  final double? ph;
  final double? oxygen;
  final double? waterTemp;
  final double? ec;
  final DateTime date;

  ValidationData({
    required this.notificationId,
    required this.deviceId,
    required this.deviceName,
    required this.groupId,
    required this.groupName,
    this.ph,
    this.oxygen,
    this.waterTemp,
    this.ec,
    required this.date,
  });
}

Future<List<ValidationData>> getValidationDataByDeviceId(
    String deviceId) async {
  final db = await DatabaseService().database;

  final List<Map<String, dynamic>> maps = await db.query(
    'validation_data',
    where: 'device_id = ?',
    whereArgs: [deviceId],
  );

  return List.generate(
    maps.length,
    (i) => ValidationData(
      notificationId: maps[i]['notification_id'],
      deviceId: maps[i]['device_id'],
      deviceName: maps[i]['device_name'],
      groupId: maps[i]['group_id'],
      groupName: maps[i]['group_name'],
      ph: maps[i]['ph'],
      oxygen: maps[i]['oxygen'],
      waterTemp: maps[i]['water_temp'],
      ec: maps[i]['ec'],
      date: DateTime.parse(maps[i]['date']),
    ),
  );
}

Future<void> hasValidationData() async {
  final db = await DatabaseService().database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM validation_data');
  final count = Sqflite.firstIntValue(result) ?? 0;
  validationNotifier.value = count < 1;
}
