import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:imon_app/utils/style.dart';
import '../../models/ponds_data.dart';
import '../../models/validation_data.dart';
import '../../services/database_services.dart';
import '../../services/notification_services.dart';
import '../../utils/debug.dart';
import '../../utils/timezone.dart';
import 'device_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<ValidationData> _validationData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchValidationData();
  }

  void _deleteAllNotifications() {
    deleteAllNotifications(context, () {
      setState(() {
        _validationData.clear();
      });
    });
  }

  Future<void> _fetchValidationData() async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query('validation_data');

    final data = List.generate(
      maps.length,
      (i) => ValidationData(
        notificationId: maps[i]['id'],
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

    setState(() {
      _validationData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyling.backgColor,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: const Color.fromARGB(255, 95, 115, 193),
        title: const Center(
          child: Text(
            'Pemberitahuan',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteAllNotifications,
            tooltip: 'Hapus Semua Notifikasi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _validationData.isEmpty
              ? Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 0.75,
                        child: SvgPicture.asset(
                          'assets/images/landing_page.svg',
                          height: 250,
                          width: 250,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text('Tidak ada notifikasi'),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 0.75,
                        child: SvgPicture.asset(
                          'assets/images/landing_page.svg',
                          height: 250,
                          width: 250,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: _validationData.length,
                        itemBuilder: (context, index) {
                          final data = _validationData[index];
                            return Dismissible(
                              key: ValueKey(data.notificationId),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) {
                                deleteNotification(
                                  data.notificationId,
                                  context,
                                      () {
                                    setState(() {
                                      _validationData.removeWhere((item) =>
                                      item.notificationId == data.notificationId);
                                    });
                                  },
                                );
                              },
                              background: Card(
                                elevation: 4.0,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                color: Colors.red,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 16.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              child: Card(
                                elevation: 4.0,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.notifications,
                                    color: Colors.deepOrangeAccent,
                                    size: 30,
                                  ),
                                  title: Text(
                                    data.deviceName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '''
${data.groupName}
${formatDateWithTimeZone(data.date)}
                              ''',
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey.shade400,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    String deviceId = data.deviceId;
                                    String deviceName = data.deviceName;
                                    DateTime temp = data.date;
                                    temp = DateTime(temp.year, temp.month, temp.day, 23, 59, 59);

                                    final matchingPond = ponds.firstWhere(
                                          (pond) => pond['id'] == data.groupId,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    if (matchingPond.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DevicePage(
                                            deviceId: deviceId,
                                            deviceName: deviceName,
                                            deviceGroupName: data.groupName,
                                            thresholdStatus: matchingPond['threshold_status'],
                                            phMax: double.tryParse(matchingPond['ph_max'].toString()) ?? 0.0,
                                            phMin: double.tryParse(matchingPond['ph_min'].toString()) ?? 0.0,
                                            ecMax: double.tryParse(matchingPond['ec_max'].toString()) ?? 0.0,
                                            ecMin: double.tryParse(matchingPond['ec_min'].toString()) ?? 0.0,
                                            tempMax: double.tryParse(matchingPond['temp_max'].toString()) ?? 0.0,
                                            tempMin: double.tryParse(matchingPond['temp_min'].toString()) ?? 0.0,
                                            oMax: double.tryParse(matchingPond['oxygen_max'].toString()) ?? 0.0,
                                            oMin: double.tryParse(matchingPond['oxygen_min'].toString()) ?? 0.0,
                                            fromNotification: true,
                                            specificDate: temp.toUtc(),
                                          ),
                                        ),
                                      );
                                    } else {
                                      debugMode("No matching pond found for group ID: ${data.groupId}");
                                    }
                                  },
                                ),
                              ),
                            );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
