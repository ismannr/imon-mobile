import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:imon_app/services/database_services.dart';
import 'package:intl/intl.dart';
import '../../services/monitoring_data_service.dart';
import '../../utils/debug.dart';
import '../../utils/timezone.dart';
import 'graph.dart';
import '../../utils/style.dart';

class DevicePage extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String deviceGroupName;
  final DateTime? specificDate;
  final bool thresholdStatus;
  final bool fromNotification;
  final double phMax;
  final double phMin;
  final double ecMax;
  final double ecMin;
  final double tempMax;
  final double tempMin;
  final double oMax;
  final double oMin;

  const DevicePage(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      required this.thresholdStatus,
      required this.phMax,
      required this.phMin,
      required this.ecMax,
      required this.ecMin,
      required this.tempMax,
      required this.tempMin,
      required this.oMax,
      required this.oMin,
      required this.fromNotification,
      this.specificDate,
      required this.deviceGroupName});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  List<FlSpot> _oxygenSpots = [];
  List<FlSpot> _tempSpots = [];
  List<FlSpot> _ecSpots = [];
  List<FlSpot> _phSpots = [];
  double _latest = 0;
  double _earliest = 0;
  DateTime selectedDate = DateTime.now();
  Timer? _timer;
  bool isAutoFetch = false;

  @override
  void initState() {
    super.initState();
    if (widget.fromNotification && widget.specificDate != null) {
      selectedDate = widget.specificDate!;
      _fetchDeviceData(formatDateString(widget.specificDate!));
    } else {
      _fetchDeviceMonitoringData();
      _startAutoFetch();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoFetch() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      selectedDate = DateTime.now();
      _fetchDeviceMonitoringData();
    });
    isAutoFetch = true;
  }

  void _stopAutoFetch() {
    if (_timer != null) {
      _timer!.cancel();
      isAutoFetch = false;
    }
  }

  Future<void> _fetchDeviceData(String formattedDate) async {
    print(formattedDate);
    if (formattedDate != "") {
      if (isAutoFetch) {
        _stopAutoFetch();
      }

      try {
        final data = await getDeviceMonitorData(
          deviceId: widget.deviceId,
          date: formattedDate,
          interval: '1439m',
        );

        List<DateTime> timestamps = data[4];

        double latest = timestamps
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .millisecondsSinceEpoch
            .toDouble();
        double earliest = timestamps
            .reduce((a, b) => a.isBefore(b) ? a : b)
            .millisecondsSinceEpoch
            .toDouble();

        setState(() {
          _oxygenSpots = mapDataToSpots(data[0], data[4]);
          _tempSpots = mapDataToSpots(data[1], data[4]);
          _ecSpots = mapDataToSpots(data[2], data[4]);
          _phSpots = mapDataToSpots(data[3], data[4]);
          _latest = latest;
          _earliest = earliest;
        });
      } catch (e) {
        debugMode('Error: $e');
      }
    } else if (formattedDate == "" && !isAutoFetch) {
      _fetchDeviceMonitoringData();
      _startAutoFetch();
    }
  }

  Future<void> _fetchDeviceMonitoringData() async {
    final deviceData = await DatabaseService.instance
        .getDeviceMonitorDataById(widget.deviceId);

    if (deviceData != null) {
      final timestamps = deviceData.timeStamp;
      double latest = timestamps
          .reduce((a, b) => a.isAfter(b) ? a : b)
          .millisecondsSinceEpoch
          .toDouble();
      double earliest = timestamps
          .reduce((a, b) => a.isBefore(b) ? a : b)
          .millisecondsSinceEpoch
          .toDouble();
      setState(() {
        _oxygenSpots = mapDataToSpots(deviceData.oxygen, timestamps);
        _tempSpots = mapDataToSpots(deviceData.waterTemp, timestamps);
        _ecSpots = mapDataToSpots(deviceData.ec, timestamps);
        _phSpots = mapDataToSpots(deviceData.ph, timestamps);
        _latest = latest;
        _earliest = earliest;
      });
    } else {
      setState(() {
        _oxygenSpots = [];
        _tempSpots = [];
        _ecSpots = [];
        _phSpots = [];
        _latest = 0.0;
        _earliest = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyling.backgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 8),
                const Text("Kolam"),
              ],
            ),
            Stack(
              children: [
                Center(
                  child: Text(
                    widget.deviceName,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        String formattedDate = "";
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          confirmText: "OK",
                          cancelText: "Kembali",
                          helpText: "Pilih Tanggal",
                        );

                        if (pickedDate != null) {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            23,
                            59,
                            59,
                          );
                          if (pickedDate.day != DateTime.now().day) {
                            formattedDate =
                                DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")
                                    .format(selectedDate.toUtc());
                          }
                          await _fetchDeviceData(formattedDate);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
            Center(
              child: Text(
                widget.deviceGroupName,
                style: const TextStyle(
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            // Graph Widgets
            FLGraphWidget(
              title: 'Kadar Oksigen',
              param: _oxygenSpots,
              showAsInteger: false,
              isThresholdActive: widget.thresholdStatus,
              thresholdMax: widget.oMax,
              thresholdMin: widget.oMin,
              maxY: 20,
              minY: 0,
              section: 5,
              unit: 'mg/L',
              maxScale: 1.2,
              minScale: 0.8,
              date: selectedDate,
            ),
            FLGraphWidget(
              title: 'Padatan Terlarut',
              param: _ecSpots,
              showAsInteger: true,
              isThresholdActive: widget.thresholdStatus,
              thresholdMax: widget.ecMax,
              thresholdMin: widget.ecMin,
              maxY: 1000,
              minY: 0,
              section: 5,
              unit: 'millisiemens',
              maxScale: 1.01,
              minScale: 0.99,
              date: selectedDate,
            ),
            FLGraphWidget(
              title: 'pH',
              param: _phSpots,
              showAsInteger: false,
              isThresholdActive: widget.thresholdStatus,
              thresholdMax: widget.phMax,
              thresholdMin: widget.phMin,
              maxY: 14,
              minY: 0,
              section: 4,
              unit: 'pH',
              maxScale: 1.2,
              minScale: 0.8,
              date: selectedDate,
            ),
            FLGraphWidget(
              title: 'Temperatur',
              param: _tempSpots,
              showAsInteger: false,
              isThresholdActive: widget.thresholdStatus,
              thresholdMax: widget.tempMax,
              thresholdMin: widget.tempMin,
              maxY: 50,
              minY: 0,
              section: 5,
              unit: 'Celsius',
              maxScale: 1.2,
              minScale: 0.8,
              date: selectedDate,
            ),
          ],
        ),
      ),
    );
  }
}
