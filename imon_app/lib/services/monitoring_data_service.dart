import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:imon_app/services/database_services.dart';
import '../models/monitoring_data.dart';
import '../models/validation_data.dart';
import '../utils/debug.dart';
import 'auth_services.dart';

Future<List<dynamic>> getDeviceMonitorData({
  required String deviceId,
  String? date,
  String? interval,
}) async {
  final Map<String, dynamic> requestBody = {
    'date': date ?? '',
    'device_id': deviceId,
    'interval': interval ?? '',
  };
  final headers = await getHeaders();
  final Uri url = Uri.parse('${getBaseUrl()}/device/monitor-date-time');
  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseBody = jsonDecode(response.body);

    final csvData = responseBody['data'];
    if (csvData != null) {
      return parseCsvData(csvData);
    } else {
      throw Exception('CSV data not found in response');
    }
  } else {
    throw Exception('Failed to fetch monitor data');
  }
}

Future<void> insertValidationFromApi(Map<String, dynamic> responseBody) async {
  final data = responseBody['data'];
  if (data == null) {
    throw Exception('Missing data field in API response');
  }

  final validationsData = data['Validations'] as List<dynamic>? ?? [];
  if (validationsData.isEmpty) {
    debugMode('No validations to insert.');
    return;
  }

  for (final validation in validationsData) {
    try {
      final validationData = ValidationData(
        notificationId: validation['notification_id'] as String? ?? '',
        deviceId: validation['device_id'] as String? ?? '',
        deviceName: validation['device_name'] as String? ?? '',
        groupId: validation['group_id'] as String? ?? '',
        groupName: validation['group_name'] as String? ?? '',
        ph: (validation['ph'] as num?)?.toDouble(),
        oxygen: (validation['oxygen'] as num?)?.toDouble(),
        waterTemp: (validation['water_temp'] as num?)?.toDouble(),
        ec: (validation['ec'] as num?)?.toDouble(),
        date: DateTime.tryParse(validation['date'] as String? ?? '') ??
            DateTime.now(),
      );

      await DatabaseService.instance.updateValidationData(validationData);
    } catch (e) {
      debugMode('Error inserting validation: $e');
    }
  }
}

Future<DeviceMonitorData> insertMonitorFromApi(
    Map<String, dynamic> responseBody) async {
  final data = responseBody['data'];
  if (data == null) {
    throw Exception('Missing data field in API response');
  }

  final csvData = data['CsvData'] as String?;
  if (csvData == null || csvData.isEmpty) {
    throw Exception('Invalid or missing CsvData in API response');
  }

  final csvLines =
      csvData.split('\n').where((line) => line.trim().isNotEmpty).toList();

  if (csvLines.length == 1) {
    return DeviceMonitorData(
      id: '',
      ph: [],
      oxygen: [],
      waterTemp: [],
      ec: [],
      timeStamp: [],
    );
  }

  final headerRow = csvLines[0].split(',');
  final phIndex = headerRow.indexOf('PhLevel');
  final oxygenIndex = headerRow.indexOf('OxygenLevel');
  final waterTempIndex = headerRow.indexOf('WaterTemp');
  final ecIndex = headerRow.indexOf('EcLevel');
  final timestampIndex = headerRow.indexOf('TimeStamp');
  final idIndex = headerRow.indexOf('ID');
  if ([phIndex, oxygenIndex, waterTempIndex, ecIndex, timestampIndex, idIndex]
      .any((index) => index == -1)) {
    throw Exception('One or more required columns not found in CsvData');
  }

  final deviceId = csvLines[1].split(',')[idIndex];

  final List<double> ph = [];
  final List<double> oxygen = [];
  final List<double> waterTemp = [];
  final List<double> ec = [];
  final List<DateTime> timeStamp = [];

  for (var i = 1; i < csvLines.length; i++) {
    final row = csvLines[i].split(',');
    if (row.length <=
        [phIndex, oxygenIndex, waterTempIndex, ecIndex, timestampIndex]
            .reduce((a, b) => a > b ? a : b)) {
      continue;
    }
    try {
      ph.add(double.parse(row[phIndex]));
      oxygen.add(double.parse(row[oxygenIndex]));
      waterTemp.add(double.parse(row[waterTempIndex]));
      ec.add(double.parse(row[ecIndex]));
      timeStamp.add(DateTime.parse(row[timestampIndex]));
    } catch (e) {
      debugMode('Error parsing row $i: $e');
    }
  }

  DeviceMonitorData newData = DeviceMonitorData(
    id: deviceId,
    ph: ph,
    oxygen: oxygen,
    waterTemp: waterTemp,
    ec: ec,
    timeStamp: timeStamp,
  );

  await DatabaseService.instance.mapMonitorData(newData);

  return newData;
}

Future<void> getAllDeviceMonitorData(String interval, String date) async {
  final headers = await getHeaders();
  final Uri url =
      Uri.parse('https://iot.andamantau.com/device/monitor/$interval/$date');
  final response = await http.get(
    url,
    headers: headers,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseBody = jsonDecode(response.body);

    final data = responseBody['data'];
    if (data == null) {
      throw Exception('Data field is missing in API response');
    }
    try {
      await insertMonitorFromApi(responseBody);
      await insertValidationFromApi(responseBody);
    } catch (e) {
      throw Exception('Failed to parse monitor data: $e');
    }
  } else {
    throw Exception('Failed to fetch monitor data: ${response.statusCode}');
  }
}

List<dynamic> parseCsvData(String csvData) {
  final List<String> rows = csvData.split('\n');
  final List<String> headers = rows[0].split(',');

  List<double> oxygen = [];
  List<double> ec = [];
  List<double> ph = [];
  List<double> temp = [];
  List<DateTime> timestamp = [];

  for (int i = 1; i < rows.length; i++) {
    if (rows[i].isNotEmpty) {
      final List<String> columns = rows[i].split(',');
      for (int j = 0; j < headers.length; j++) {
        String header = headers[j].trim();
        String value = columns[j].trim();
        if (header == 'OxygenLevel') {
          oxygen.add(double.parse(value));
        } else if (header == 'WaterTemp') {
          temp.add(double.parse(value));
        } else if (header == 'EcLevel') {
          ec.add(double.parse(value));
        } else if (header == 'PhLevel') {
          ph.add(double.parse(value));
        } else if (header == 'TimeStamp') {
          timestamp.add(DateTime.parse(value));
        }
      }
    }
  }
  return [oxygen, temp, ec, ph, timestamp];
}

List<FlSpot> mapDataToSpots(List<double> values, List<DateTime> timestamps) {
  return List.generate(
    values.length,
    (index) {
      double x = timestamps[index].millisecondsSinceEpoch.toDouble();
      double y = values[index];
      return FlSpot(x, y);
    },
  );
}
