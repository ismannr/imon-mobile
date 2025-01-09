
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imon_app/pages/auth/landing_page.dart';
import 'package:imon_app/services/scheduler_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:imon_app/utils/http.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = HttpOverrider();
  await Permission.notification.request();
  await initializeService();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LandingPage(),
    locale: Locale('id'),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('en'),
      Locale('id'),
    ],
  ));

}