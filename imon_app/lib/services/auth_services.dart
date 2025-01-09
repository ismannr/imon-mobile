import 'package:imon_app/services/profile_picture_services.dart';
import 'package:imon_app/services/scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:imon_app/pages/auth/landing_page.dart';
import 'package:http/http.dart' as http;

import '../models/ponds_data.dart';
import '../utils/alert.dart';
import 'database_services.dart';

class CookieUtils {
  static String? _cookie;

  static Future<String?> getCookie() async {
    if (_cookie != null) {
      return _cookie;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('cookie'); // Consistent 'cookie' key
  }

  static Future<void> setCookie(String cookie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookie', cookie); // Consistent 'cookie' key
    _cookie = cookie;
  }

  static Future<void> clearCookie() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('cookie');
    _cookie = null;
  }
}

Future<String?> getCookie() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('cookie');
}

Future<Map<String, String>> getHeaders() async {
  String? savedCookie = await getCookie();
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };

  if (savedCookie != null) {
    headers['Cookie'] = savedCookie;
  }

  return headers;
}

String getBaseUrl() {
  return 'https://iot.andamantau.com';
}

Future<bool> checkLoginStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedCookie = prefs.getString('cookie');
  if (savedCookie == null) {
    return false;
  }

  var url = Uri.parse('${getBaseUrl()}/user');
  try {
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      await prefs.remove('cookie');
      return false;
    }
  } catch (error) {
    await prefs.remove('cookie');
    return false;
  }
}

Future<bool> loginStatusChecker(BuildContext context, Function setState) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedCookie = prefs.getString('cookie');

  if (savedCookie == null) {
    return false;
  }

  var url = Uri.parse('${getBaseUrl()}/user');

  try {
    final headers = await getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      await prefs.remove('cookie');
      if (context.mounted) {
        sessionTimeout(context);
      }
      return false;
    }
  } catch (error) {
    await prefs.remove('cookie');
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
    }
    return false;
  }
}

void sessionTimeout(BuildContext context){
  showAlert(
    context,
    title: "Sesi Berakhir",
    message: "Sesi anda telah berakhir, silahkan masuk kembali",
    onClose: () async {
      ponds = [];
      final prefs = await SharedPreferences.getInstance();
      stopBackgroundService();
      await deleteLocalProfilePicture();
      await DatabaseService.instance.closeDb();
      await prefs.remove('cookie');
      await prefs.remove('user_data');
      if(context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      }
    },
    dismissible: false,
  );
}

Future<void> logout() async {
  ponds = [];
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('cookie');
  await prefs.remove('user_data');
  stopBackgroundService();
  await deleteLocalProfilePicture();
  await DatabaseService.instance.closeDb();
}