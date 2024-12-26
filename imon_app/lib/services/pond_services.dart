import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_services.dart';

class PondServices {
  static Future<List<Map<String, dynamic>>> fetchPonds() async {
    final url = Uri.parse('${getBaseUrl()}/group');
    try {
      final headers = await getHeaders();
      final response = await http.get(url, headers: headers);

      final responseBody = json.decode(response.body);
      if (responseBody['data'] != null && responseBody['data'] is List) {
        return (responseBody['data'] as List).map((item) {
          return {
            'id': item['ID'],
            'group_name': item['group_name'],
            'number_of_device': item['number_of_device'],
            'ph_max': item['ph_max'],
            'ph_min': item['ph_min'],
            'ec_max': item['ec_max'],
            'ec_min': item['ec_min'],
            'temp_max': item['temp_max'],
            'temp_min': item['temp_min'],
            'oxygen_max': item['oxygen_max'],
            'oxygen_min': item['oxygen_min'],
            'threshold_status': item['threshold_status']
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Gagal memuat kolam: $e');
    }
  }

  static Future<int> countPonds() async {
    try {
      final ponds = await fetchPonds();
      return ponds.length;
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<void> setThreshold({
    required String pondId,
    required double phMax,
    required double phMin,
    required double ecMax,
    required double ecMin,
    required double tempMax,
    required double tempMin,
    required double oxygenMax,
    required double oxygenMin,
    required bool thresholdStatus,
  }) async {
    final url = Uri.parse('${getBaseUrl()}/group/set-threshold');
    try {
      final headers = await getHeaders();

      final requestBody = {
        "ID": pondId,
        "ph_max": phMax,
        "ph_min": phMin,
        "ec_max": ecMax,
        "ec_min": ecMin,
        "temp_max": tempMax,
        "temp_min": tempMin,
        "oxygen_max": oxygenMax,
        "oxygen_min": oxygenMin,
        "threshold_status": thresholdStatus,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update threshold: ${response.body}');
      }
    } catch (e) {
      throw 'Error setting threshold: $e';
    }
  }
}

