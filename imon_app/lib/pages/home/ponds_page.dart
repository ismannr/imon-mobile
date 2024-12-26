import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:imon_app/pages/home/pond_page.dart';
import 'package:imon_app/utils/alert.dart';
import 'package:imon_app/services/auth_services.dart';
import 'package:imon_app/utils/style.dart';
import 'dart:convert';

import '../../models/ponds_data.dart';

class PondsPage extends StatefulWidget {
  const PondsPage({super.key});

  @override
  State<PondsPage> createState() => _PondsPageState();
}

class _PondsPageState extends State<PondsPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<String?> _promptRenamePond(
      BuildContext context, String currentName) async {
    final TextEditingController controller =
        TextEditingController(text: currentName);
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubah nama kolam'),
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

  Future<void> _renamePond(String pondId, String newName) async {
    final url = Uri.parse('${getBaseUrl()}/group/$pondId');
    try {
      final headers = await getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({
          'new_group_name': newName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final pond = ponds.firstWhere((p) => p['id'] == pondId);
          pond['group_name'] = newName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil mengubah nama kolam')),
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

  Future<bool> _confirmDeletePond(BuildContext context, String pondName) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hapus Kolam'),
              content:
                  Text('Apakah anda yakin untuk menghapus kolam "$pondName"?'),
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

  Future<void> _deletePond(String pondId) async {
    final url = Uri.parse('${getBaseUrl()}/group/$pondId');
    try {
      final headers = await getHeaders();
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          ponds.removeWhere((pond) => pond['id'] == pondId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kolam berhasil dihapus')),
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
                      'Kolam Saya',
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
                  final pond = ponds[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PondPage(
                            pondId: pond['id'].toString(),
                            pondName: pond['group_name'],
                            thresholdStatus: pond['threshold_status'],
                            phMax: double.tryParse(pond['ph_max'].toString()) ?? 0.0,
                            phMin: double.tryParse(pond['ph_min'].toString()) ?? 0.0,
                            ecMax: double.tryParse(pond['ec_max'].toString()) ?? 0.0,
                            ecMin: double.tryParse(pond['ec_min'].toString()) ?? 0.0,
                            tempMax: double.tryParse(pond['temp_max'].toString()) ?? 0.0,
                            tempMin: double.tryParse(pond['temp_min'].toString()) ?? 0.0,
                            oMax: double.tryParse(pond['oxygen_max'].toString()) ?? 0.0,
                            oMin: double.tryParse(pond['oxygen_min'].toString()) ?? 0.0,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0))),
                      child: ListTile(
                        title: Text(pond['group_name'] ?? 'N/A'),
                        subtitle: Text(
                          'Jumlah perangkat: ${pond['number_of_device'] ?? 'N/A'}',
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.settings,
                              color: AppStyling.buttonColor),
                          onSelected: (String value) async {
                            if (value == 'rename') {
                              final newName = await _promptRenamePond(
                                  context, pond['group_name']);
                              if (newName != null && newName.isNotEmpty) {
                                await _renamePond(pond['id'], newName);
                              }
                            } else if (value == 'delete') {
                              final shouldDelete = await _confirmDeletePond(
                                  context, pond['group_name']);
                              if (shouldDelete) {
                                await _deletePond(pond['id']);
                              }
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Ubah Nama'),
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
                childCount: ponds.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
