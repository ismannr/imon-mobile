import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/monitoring_data.dart';
import '../models/validation_data.dart';
import '../utils/debug.dart';

class DatabaseService {
  DatabaseService._init();
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  factory DatabaseService() {
    return instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    print("db is null");
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'monitor_data.db');
    print(path);
    print('creating database');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE device_monitor_data (
          id TEXT PRIMARY KEY,
          ph TEXT NOT NULL,          -- Stores serialized list of doubles as a comma-separated string
          oxygen TEXT NOT NULL,      -- Stores serialized list of doubles as a comma-separated string
          waterTemp TEXT NOT NULL,   -- Stores serialized list of doubles as a comma-separated string
          ec TEXT NOT NULL,          -- Stores serialized list of doubles as a comma-separated string
          timeStamp TEXT NOT NULL    -- Stores serialized list of timestamps as a comma-separated string
        )
      ''');

        await db.execute('''
        CREATE TABLE validation_data (
          id TEXT PRIMARY KEY,
          device_id TEXT NOT NULL,
          device_name TEXT NOT NULL,
          group_id TEXT NOT NULL,
          group_name TEXT NOT NULL,
          ph REAL,
          oxygen REAL,
          water_temp REAL,
          ec REAL,
          date TEXT NOT NULL
        )
      ''');
      },
    );
  }

  Future<int> mapMonitorData(DeviceMonitorData deviceMonitorData) async {
    final db = await instance.database;

    final existingData = await db.query(
      'device_monitor_data',
      where: 'id = ?',
      whereArgs: [deviceMonitorData.id],
      limit: 1,
    );

    if (existingData.isNotEmpty) {
      final currentData = DeviceMonitorData.fromMap(existingData.first);

      final updatedData = DeviceMonitorData(
        id: currentData.id,
        ph: currentData.ph + deviceMonitorData.ph,
        oxygen: currentData.oxygen + deviceMonitorData.oxygen,
        waterTemp: currentData.waterTemp + deviceMonitorData.waterTemp,
        ec: currentData.ec + deviceMonitorData.ec,
        timeStamp: currentData.timeStamp + deviceMonitorData.timeStamp,
      );

      final updateResult = await db.update(
        'device_monitor_data',
        updatedData.toMap(),
        where: 'id = ?',
        whereArgs: [deviceMonitorData.id],
      );
      return updateResult;
    } else {
      final insertResult = await db.insert(
        'device_monitor_data',
        deviceMonitorData.toMap(),
      );
      return insertResult;
    }
  }

  Future<int> updateValidationData(ValidationData validationData) async {
    final db = await instance.database;

    final existingRecord = await db.query(
      'validation_data',
      where: 'id = ?',
      whereArgs: [validationData.notificationId],
      limit: 1,
    );

    if (existingRecord.isNotEmpty) {
      debugMode('Validation with id ${validationData.notificationId} already exists. Skipping insert.');
      return 0;
    }

    return await db.insert(
      'validation_data',
      {
        'id': validationData.notificationId,
        'device_id': validationData.deviceId,
        'device_name': validationData.deviceName,
        'group_id': validationData.groupId,
        'group_name': validationData.groupName,
        'ph': validationData.ph,
        'oxygen': validationData.oxygen,
        'water_temp': validationData.waterTemp,
        'ec': validationData.ec,
        'date': validationData.date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DeviceMonitorData?> getDeviceMonitorDataById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'device_monitor_data',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return DeviceMonitorData.fromMap(result.first);
    } else {
      return null;
    }
  }


  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.transaction((txn) async {
        await txn.delete('device_monitor_data');
        await txn.delete('validation_data');
      });

      await _database!.close();
      _database = null;
    }
  }



  Future<void> clearDatabase() async {
    String path = join(await getDatabasesPath(), 'monitor_data.db');

    bool databaseExists = await databaseFactory.databaseExists(path);

    if (databaseExists) {
      await deleteDatabase(path);
    }
  }
}

