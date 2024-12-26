import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:imon_app/utils/alert.dart';
import 'package:imon_app/services/auth_services.dart';
import 'package:imon_app/utils/style.dart';
import 'dart:convert';

import '../../models/ponds_data.dart';
import '../../services/device_service.dart';
import '../../services/pond_services.dart';
import 'device_page.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List devices = [];

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  Future<void> loadDevices() async {
    try {
      final deviceList = await DeviceService.fetchDevices();
      setState(() {
        devices = deviceList;
      });
    } catch (e) {
      showErrorAlert(context, e.toString());
    }
  }

  void _onDeviceDeleted(String deviceId) {
    setState(() {
      devices = devices.where((device) => device['ID'] != deviceId).toList();
    });
  }

  Future<void> _deleteDevice(String deviceId) async {
    await unassignDevice(context, deviceId, () => _onDeviceDeleted(deviceId));
  }

  Future<String?> _promptShowDeviceInfo(
      BuildContext context, String id, String pondName) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informasi Perangkat'),
          content: Text('ID Perangkat:\n$id\n\nNama Kolam:\n$pondName'),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ID perangkat sudah tersalin')),
                );
              },
              child: const Text('Salin ID'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, id);
              },
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteDevice(id);
              },
              child: const Text(
                'Keluarkan dari kolam',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _promptRenameDevices(
      BuildContext context, String currentName) async {
    final TextEditingController controller =
        TextEditingController(text: currentName);
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ganti nama perangkat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Masukkan nama baru'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Ubah Nama'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameDevice(String deviceId, String newName) async {
    final url = Uri.parse('${getBaseUrl()}/device/$deviceId');
    try {
      final headers = await getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({
          'name': newName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final device = devices.firstWhere((p) => p['id'] == deviceId);
          device['name'] = newName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama perangkat berhasil diganti')),
        );
      } else {
        showAlert(context,
            title: "Keluar",
            message: "Sesi anda telah berakhir, silahkan masuk kembali");
      }
    } catch (e) {
      showErrorAlert(context, '$e');
    }
  }

  Future<bool> _confirmDeleteDevice(
      BuildContext context, String deviceName) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hapus Perangkat'),
              content: Text(
                  'Apakah anda yakin untuk menghapus perangkat "$deviceName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Kembali'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child:
                      const Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deletePond(String deviceId) async {
    final url = Uri.parse('${getBaseUrl()}/device/delete/$deviceId');
    try {
      final headers = await getHeaders();
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          devices.removeWhere((pond) => pond['id'] == deviceId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perangkat berhasil dihapus')),
        );
      } else {
        showAlert(context,
            title: "Keluar",
            message: "Sesi anda telah berakhir, silahkan masuk kembali");
      }
    } catch (e) {
      showErrorAlert(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyling.backgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Center(
                    child: Text(
                      'Perangkat Saya',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 74, 106, 169),
                      ),
                    ),
                  )),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final device = devices[index];
                  return GestureDetector(
                    onTap: () {
                      final matchingPond = ponds.firstWhere(
                        (pond) => pond['id'] == device['group_id'],
                        orElse: () => <String, dynamic>{},
                      );
                      print(matchingPond);
                      if (matchingPond.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DevicePage(
                              deviceId: device['id'].toString(),
                              deviceName: device['name'].toString(),
                              deviceGroupName: device['group_name'].toString(),
                              thresholdStatus: matchingPond['threshold_status'],
                              phMax: double.tryParse(
                                      matchingPond['ph_max'].toString()) ??
                                  0.0,
                              phMin: double.tryParse(
                                      matchingPond['ph_min'].toString()) ??
                                  0.0,
                              ecMax: double.tryParse(
                                      matchingPond['ec_max'].toString()) ??
                                  0.0,
                              ecMin: double.tryParse(
                                      matchingPond['ec_min'].toString()) ??
                                  0.0,
                              tempMax: double.tryParse(
                                      matchingPond['temp_max'].toString()) ??
                                  0.0,
                              tempMin: double.tryParse(
                                      matchingPond['temp_min'].toString()) ??
                                  0.0,
                              oMax: double.tryParse(
                                      matchingPond['oxygen_max'].toString()) ??
                                  0.0,
                              oMin: double.tryParse(
                                      matchingPond['oxygen_min'].toString()) ??
                                  0.0,
                              fromNotification: false,
                            ),
                          ),
                        );
                      }
                    },
                    child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0))),
                      child: ListTile(
                        title: Text(device['name'] ?? 'N/A'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.settings,
                              color: AppStyling.buttonColor),
                          onSelected: (String value) async {
                            if (value == 'info') {
                              await _promptShowDeviceInfo(
                                  context,
                                  device['id'] ?? 'N/A',
                                  device['group_name'] ??
                                      'Perangkat belum ditempatkan pada kolam');
                              await loadDevices();
                            }
                            if (value == 'add') {
                              await promptAddDeviceToPond(
                                context,
                                deviceId: device['id'] ?? 'N/A',
                                fetchPonds: PondServices.fetchPonds,
                                addDeviceToPond: assignDeviceToPond,
                                fetchDevices: loadDevices,
                                onPondSelected: (pondId, pondName) async {
                                  await confirmDeviceMapping(
                                    context,
                                    deviceId: device['id'] ?? 'N/A',
                                    pondId: pondId,
                                    pondName: pondName,
                                    addDeviceToPond: assignDeviceToPond,
                                    fetchDevices: loadDevices,
                                  );
                                },
                                showErrorAlert: (errorMessage) {
                                  showErrorAlert(context, errorMessage);
                                },
                              );
                            }
                            if (value == 'rename') {
                              final newName = await _promptRenameDevices(
                                  context, device['name']);
                              if (newName != null && newName.isNotEmpty) {
                                await _renameDevice(device['id'], newName);
                              }
                            } else if (value == 'delete') {
                              final shouldDelete = await _confirmDeleteDevice(
                                  context, device['name']);
                              if (shouldDelete) {
                                await _deletePond(device['id']);
                              }
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'info',
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Informasi'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add',
                              child: Row(
                                children: [
                                  Icon(Icons.add, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Tambahkan ke kolam'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Ubah nama'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Hapus'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: devices.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
