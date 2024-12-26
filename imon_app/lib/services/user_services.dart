import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_services.dart';
import '../utils/debug.dart';

Future<Map<String, dynamic>> fetchUserData() async {
  final profileUrl = Uri.parse('${getBaseUrl()}/user');

  try {
    final headers = await getHeaders();
    final response = await http.get(profileUrl, headers: headers);

    if (response.statusCode == 200) {
      final profileData = json.decode(response.body)['data'];

      if (profileData['gender'] == 'MALE') {
        profileData['gender'] = 'Laki-Laki';
      } else if (profileData['gender'] == 'FEMALE') {
        profileData['gender'] = 'Perempuan';
      }

      return profileData;
    } else {
      if (kDebugMode) {
        print(
            'Failed to fetch user data. Status code: ${response.statusCode}, body: ${response.body}');
      }
    }
  } catch (e) {
    debugMode(e.toString());
  }

  return {
    'name': 'N/A',
    'email': 'N/A',
    'phone': 'N/A',
    'address': 'N/A',
    'city': 'N/A',
    'province': 'N/A',
    'businessName': 'N/A',
    'businessDesc': 'N/A',
    'password': 'N/A',
    'confirmPassword': 'N/A',
  };
}

Future<String?> fetchUserPicture() async {
  final pictureUrl = Uri.parse('${getBaseUrl()}/user/profile-picture');

  try {
    final headers = await getHeaders();
    final response = await http.get(pictureUrl, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else if (response.statusCode == 204) {
      return null; // No profile picture
    } else {
      if (kDebugMode) {
        print(
            'Failed to fetch user picture. Status code: ${response.statusCode}, body: ${response.body}');
      }
    }
  } catch (e) {
    debugMode(e.toString());
  }
  return null;
}

Future<Map<String, dynamic>> fetchUserProfile() async {
  final userData = await fetchUserData();
  final userPicture = await fetchUserPicture();

  return {
    ...userData,
    'profilePictureUrl': userPicture,
  };
}