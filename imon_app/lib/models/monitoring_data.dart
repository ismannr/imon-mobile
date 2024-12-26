import '../services/database_services.dart';

class DeviceMonitorData {
  final String id;
  final List<double> ph;
  final List<double> oxygen;
  final List<double> waterTemp;
  final List<double> ec;
  final List<DateTime> timeStamp;

  DeviceMonitorData({
    required this.id,
    required this.ph,
    required this.oxygen,
    required this.waterTemp,
    required this.ec,
    required this.timeStamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ph': ph.join(','),
      'oxygen': oxygen.join(','),
      'waterTemp': waterTemp.join(','),
      'ec': ec.join(','),
      'timeStamp': timeStamp.map((e) => e.toIso8601String()).join(','),
    };
  }

  factory DeviceMonitorData.fromMap(Map<String, dynamic> map) {
    return DeviceMonitorData(
      id: map['id'],
      ph: (map['ph'] as String).split(',').map(double.parse).toList(),
      oxygen: (map['oxygen'] as String).split(',').map(double.parse).toList(),
      waterTemp: (map['waterTemp'] as String).split(',').map(double.parse).toList(),
      ec: (map['ec'] as String).split(',').map(double.parse).toList(),
      timeStamp: (map['timeStamp'] as String).split(',').map(DateTime.parse).toList(),
    );
  }
}
