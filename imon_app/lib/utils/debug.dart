import 'package:flutter/foundation.dart';

void debugMode(Object e){
  if(kDebugMode){
    print("Error: ${e.toString()}");
  }
}