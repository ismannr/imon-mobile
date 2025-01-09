import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:imon_app/utils/alert.dart';
import 'package:imon_app/services/auth_services.dart';
import 'package:imon_app/utils/style.dart';
import 'dart:convert';

import '../../services/device_service.dart';
import '../../services/pond_services.dart';
import 'device_page.dart';

class PondPage extends StatefulWidget {
  final String pondId;
  final String pondName;
  final bool thresholdStatus;
  final double phMax;
  final double phMin;
  final double ecMax;
  final double ecMin;
  final double tempMax;
  final double tempMin;
  final double oMax;
  final double oMin;

  const PondPage(
      {super.key,
      Key? name,
      required this.pondId,
      required this.pondName,
      required this.thresholdStatus,
      required this.phMax,
      required this.phMin,
      required this.ecMax,
      required this.ecMin,
      required this.tempMax,
      required this.tempMin,
      required this.oMax,
      required this.oMin});

  @override
  State<PondPage> createState() => _PondPageState();
}

class _PondPageState extends State<PondPage> {
  List pondDevices = [];
  List userDevices = [];
  bool isLoading = true;
  late bool thresholdStatus;
  late TextEditingController phMaxController;
  late TextEditingController phMinController;
  late TextEditingController ecMaxController;
  late TextEditingController ecMinController;
  late TextEditingController tempMaxController;
  late TextEditingController tempMinController;
  late TextEditingController oxygenMaxController;
  late TextEditingController oxygenMinController;

  @override
  void initState() {
    super.initState();
    loadPondDevices();

    thresholdStatus = widget.thresholdStatus;
    phMaxController = TextEditingController(text: widget.phMax.toString());
    phMinController = TextEditingController(text: widget.phMin.toString());
    ecMaxController = TextEditingController(text: widget.ecMax.toString());
    ecMinController = TextEditingController(text: widget.ecMin.toString());
    tempMaxController = TextEditingController(text: widget.tempMax.toString());
    tempMinController = TextEditingController(text: widget.tempMin.toString());
    oxygenMaxController = TextEditingController(text: widget.oMax.toString());
    oxygenMinController = TextEditingController(text: widget.oMin.toString());
  }

  @override
  void dispose() {
    phMaxController.dispose();
    phMinController.dispose();
    ecMaxController.dispose();
    ecMinController.dispose();
    tempMaxController.dispose();
    tempMinController.dispose();
    oxygenMaxController.dispose();
    oxygenMinController.dispose();
    super.dispose();
  }

  Future<void> loadPondDevices() async {
    try {
      final devices = await DeviceService.fetchPondDevices(widget.pondId);
      setState(() {
        pondDevices = devices;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showErrorAlert(context, '$e');
      }
    }
  }

  Future<void> renameDevice(String deviceId, String currentName) async {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Nama Perangkat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nama Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text;
                final url = Uri.parse('${getBaseUrl()}/device/$deviceId');
                final headers = await getHeaders();

                final response = await http.put(
                  url,
                  headers: headers,
                  body: json.encode({'Name': newName}),
                );

                if (context.mounted) {
                  if (response.statusCode == 200) {
                    setState(() {
                      pondDevices = pondDevices.map((device) {
                        if (device['ID'] == deviceId) {
                          return {
                            ...device,
                            'name': newName,
                          };
                        }
                        return device;
                      }).toList();
                    });
                    Navigator.of(context).pop();
                  } else {
                    showAlert(context,
                        title: 'Terjadi Kesalahan',
                        message: 'Gagal mengubah nama perangkat');
                  }
                }
              },
              child: const Text('Ubah Nama'),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceId(String id) {
    showAlert(context, title: "ID Perangkat", message: id);
  }

  void _onDeviceDeleted(String deviceId) {
    setState(() {
      pondDevices =
          pondDevices.where((device) => device['ID'] != deviceId).toList();
    });
  }

  void _deleteDevice(String deviceId) {
    unassignDevice(context, deviceId, () => _onDeviceDeleted(deviceId));
  }

  Future<void> loadDevices() async {
    try {
      final deviceList = await DeviceService.fetchDevices();
      setState(() {
        userDevices = deviceList;
      });
    } catch (e) {
      showErrorAlert(context, e.toString());
    }
  }

  Future<void> pondButton(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Tambah Perangkat Ke Kolam'),
                onTap: () async {
                  assignDevice();
                  setState(() {});
                  await loadPondDevices();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_thresholding),
                title: const Text('Atur Batasan Kolam'),
                onTap: openSettingsForm,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> assignDevice() async {
    await loadDevices();
    if (userDevices.isEmpty) {
      showAlert(context,
          title: 'Terjadi Kesalahan', message: 'Tidak ada perangkat');
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pendaftaran Perangkat'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: userDevices.length,
              itemBuilder: (context, index) {
                final device = userDevices[index];
                return ListTile(
                  title: Text(device['name'] ?? 'N/A'),
                  subtitle: Text("ID Perangkat: ${device['id']}"),
                  onTap: () async {
                    Navigator.of(context).pop();

                    final deviceId = device['id'] ?? '';

                    if (deviceId.isNotEmpty) {
                      try {
                        assignDeviceToPond(widget.pondId, deviceId);
                      } catch (e) {
                        if (context.mounted) {
                          showAlert(context,
                              title: 'Terjadi Kesalahan', message: '$e');
                        }
                      }
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
            ),
          ],
        );
      },
    );
  }

  Future<void> setThreshold() async {
    try {
      await PondServices.setThreshold(
        pondId: widget.pondId,
        phMax: double.tryParse(phMaxController.text) ?? 0.0,
        phMin: double.tryParse(phMinController.text) ?? 0.0,
        ecMax: double.tryParse(ecMaxController.text) ?? 0.0,
        ecMin: double.tryParse(ecMinController.text) ?? 0.0,
        tempMax: double.tryParse(tempMaxController.text) ?? 0.0,
        tempMin: double.tryParse(tempMinController.text) ?? 0.0,
        oxygenMax: double.tryParse(oxygenMaxController.text) ?? 0.0,
        oxygenMin: double.tryParse(oxygenMinController.text) ?? 0.0,
        thresholdStatus: thresholdStatus,
      );

      if (mounted) {
        showAlert(context,
            title: 'Perubahan Tersimpan',
            message: 'Sukses melakukan penyetelan batasan sensor.');
      }
    } catch (e) {
      if (mounted) {
        showErrorAlert(context, '$e');
      }
    }
  }

  void openSettingsForm() {
    bool tempThresholdStatus = thresholdStatus;
    String tempPhMin = phMinController.text;
    String tempPhMax = phMaxController.text;
    String tempEcMin = ecMinController.text;
    String tempEcMax = ecMaxController.text;
    String tempTempMin = tempMinController.text;
    String tempTempMax = tempMaxController.text;
    String tempOxygenMin = oxygenMinController.text;
    String tempOxygenMax = oxygenMaxController.text;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20.0,
                left: 20.0,
                right: 20.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan Kolam',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Batasan Sensor'),
                      value: tempThresholdStatus,
                      onChanged: (value) {
                        setModalState(() {
                          tempThresholdStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildTempTextField(
                                'pH Min',
                                tempPhMin,
                                (value) => tempPhMin = value,
                                tempThresholdStatus,
                              ),
                              _buildTempTextField(
                                'Padatan Terlarut Min',
                                tempEcMin,
                                (value) => tempEcMin = value,
                                tempThresholdStatus,
                              ),
                              _buildTempTextField(
                                'Temp Min',
                                tempTempMin,
                                (value) => tempTempMin = value,
                                tempThresholdStatus,
                              ),
                              _buildTempTextField(
                                'Oxygen Min',
                                tempOxygenMin,
                                (value) => tempOxygenMin = value,
                                tempThresholdStatus,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: [
                              _buildTempTextField(
                                'pH Max',
                                tempPhMax,
                                (value) => tempPhMax = value,
                                tempThresholdStatus,
                              ),
                              _buildTempTextField(
                                'Padatan Terlarut Max',
                                tempEcMax,
                                (value) => tempEcMax = value,
                                tempThresholdStatus,
                              ),
                              _buildTempTextField(
                                'Temperatur Max',
                                tempTempMax,
                                (value) => tempTempMax = value,
                                tempThresholdStatus,
                              ),
                              _buildTempTextField(
                                'Oksigen Max',
                                tempOxygenMax,
                                (value) => tempOxygenMax = value,
                                tempThresholdStatus,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              thresholdStatus = tempThresholdStatus;
                              phMinController.text = tempPhMin;
                              phMaxController.text = tempPhMax;
                              ecMinController.text = tempEcMin;
                              ecMaxController.text = tempEcMax;
                              tempMinController.text = tempTempMin;
                              tempMaxController.text = tempTempMax;
                              oxygenMinController.text = tempOxygenMin;
                              oxygenMaxController.text = tempOxygenMax;
                            });

                            setThreshold(); // Call the API
                            Navigator.pop(context); // Close the modal
                          },
                          child: const Text('Simpan'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTempTextField(String label, String initialValue,
      Function(String) onChanged, bool tempStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          enabled: tempStatus,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          controller: TextEditingController.fromValue(
            TextEditingValue(text: initialValue),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            const Text("Kembali"),
          ],
        ),
        titleTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    widget.pondName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 74, 106, 169),
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  if (pondDevices.isEmpty) {
                    return _buildEmptyState();
                  }

                  final device = pondDevices[index];
                  return Card(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DevicePage(
                              deviceId: device['ID'] ?? 'N/A',
                              deviceName: device['Name'] ?? 'N/A',
                              deviceGroupName: widget.pondName,
                              phMax:
                                  double.tryParse(phMaxController.text) ?? 0.0,
                              phMin:
                                  double.tryParse(phMinController.text) ?? 0.0,
                              ecMax:
                                  double.tryParse(ecMaxController.text) ?? 0.0,
                              ecMin:
                                  double.tryParse(ecMinController.text) ?? 0.0,
                              tempMax:
                                  double.tryParse(tempMaxController.text) ??
                                      0.0,
                              tempMin:
                                  double.tryParse(tempMinController.text) ??
                                      0.0,
                              oMax: double.tryParse(oxygenMaxController.text) ??
                                  0.0,
                              oMin: double.tryParse(oxygenMinController.text) ??
                                  0.0,
                              thresholdStatus: thresholdStatus,
                              fromNotification: false,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(device['Name'] ?? 'N/A'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.settings,
                              color: AppStyling.buttonColor),
                          onSelected: (String value) {
                            if (value == 'show_id') {
                              _showDeviceId(device['ID'] ?? 'N/A');
                            } else if (value == 'edit') {
                              renameDevice(device['ID'], device['Name'] ?? '');
                            } else if (value == 'unassign') {
                              _deleteDevice(device['ID']);
                            } else if (value == 'delete') {
                              _deleteDevice(device['ID'] ?? 'N/A');
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'show_id',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Perlihatkan ID'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Ubah'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'unassign',
                              child: Row(
                                children: [
                                  Icon(Icons.remove, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Keluarkan Dari Kolam'),
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
                childCount: pondDevices.isEmpty ? 1 : pondDevices.length,
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          pondButton(context);
        },
        backgroundColor: AppStyling.buttonColor,
        child: const Icon(Icons.settings, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

Widget _buildEmptyState() {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
        // Change to empty icon
        SizedBox(height: 16),
        Text(
          'Perangkat tidak ditemukan',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    ),
  );
}
