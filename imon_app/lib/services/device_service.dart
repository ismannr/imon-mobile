import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/alert.dart';
import 'auth_services.dart';

class DeviceService {
  static Future<List<Map<String, dynamic>>> fetchDevices() async {
    final url = Uri.parse('${getBaseUrl()}/devices');
    try {
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      final responseBody = json.decode(response.body);
      if (responseBody['data'] != null && responseBody['data'] is List) {
        return (responseBody['data'] as List).map((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'group_name': item['group_name'],
            'group_id': item['group_id'],
          };
        }).toList();
      }
    } catch (e) {
      throw 'Error fetching devices: $e';
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchPondDevices(String pondId) async {
    final url = Uri.parse('${getBaseUrl()}/group/$pondId');
    try {
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['data'] != null && responseBody['data'] is List) {
          return List<Map<String, dynamic>>.from(responseBody['data']);
        } else {
          throw Exception('Invalid JSON body response');
        }
      } else {
        throw Exception('Failed to fetch pond devices. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw 'Error fetching pond devices: $e';
    }
  }

  static Future<int> countDevices() async {
    try {
      final devices = await fetchDevices();
      return devices.length;
    } catch (e) {
      throw 'Error counting devices: $e';
    }
  }
}

Future<http.Response> unassignDeviceFromPond(String deviceId) async {
  final url = Uri.parse('${getBaseUrl()}/device/to-group/$deviceId');
  final headers = await getHeaders();
  return await http.delete(url, headers: headers);
}

Future<void> unassignDevice(
    BuildContext context, String deviceId, Function onSuccess) async {
  showAlert(
    context,
    title: 'Confirmation',
    message: 'Are you sure you want to unassign this device from group?',
    confirmText: 'Delete',
    onConfirm: () async {
      try {
        final response = await unassignDeviceFromPond(deviceId);
        if (response.statusCode == 200) {
          onSuccess();
          showAlert(
            context,
            title: 'Success',
            message: 'Device unassigned successfully.',
          );
        } else {
          final responseBody = json.decode(response.body);
          final errorMessage =
              responseBody['message'] ?? 'Failed to unassigned device.';
          showAlert(context, title: 'Error', message: errorMessage);
        }
      } catch (e) {
        showAlert(
          context,
          title: 'Error',
          message: 'An error occurred: $e',
        );
      }
    },
    dismissible: false,
  );
}

Future<void> promptAddDeviceToPond(
  BuildContext context, {
  required String deviceId,
  required Future<List<Map<String, dynamic>>> Function() fetchPonds,
  required Future<void> Function(String pondId, String deviceId)
      addDeviceToPond,
  required VoidCallback fetchDevices,
  required void Function(String pondId, String pondName) onPondSelected,
  required void Function(String errorMessage) showErrorAlert,
}) async {
  try {
    final pondData = await fetchPonds();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select a Pond"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pondData.length,
              itemBuilder: (context, index) {
                final pond = pondData[index];
                return ListTile(
                  title: Text(pond['group_name']),
                  subtitle: Text("Devices: ${pond['number_of_device']}"),
                  onTap: () {
                    Navigator.of(context).pop();
                    onPondSelected(
                      pond['id'] ?? 'N/A',
                      pond['group_name'] ?? 'N/A',
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  } catch (e) {
    showErrorAlert('$e');
  }
}

Future<void> confirmDeviceMapping(
  BuildContext context, {
  required String deviceId,
  required String pondId,
  required String pondName,
  required Future<void> Function(String pondId, String deviceId)
      addDeviceToPond,
  required VoidCallback fetchDevices,
}) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm Mapping"),
        content: Text("Do you want to map the device to the pond '$pondName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await addDeviceToPond(pondId, deviceId);
              fetchDevices();
            },
            child: const Text("Confirm"),
          ),
        ],
      );
    },
  );
}

Future<void> assignDeviceToPond(String pondId, String deviceId) async {
  final url = Uri.parse('${getBaseUrl()}/device/to-group/$deviceId');
  final headers = await getHeaders();
  final body = json.encode({
    "group_id": pondId,
  });
  try {
    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
    } else {
      throw Exception("Failed to map device: ${response.body}");
    }
  } catch (e) {
    throw Exception("Error mapping device to pond: $e");
  }
}

