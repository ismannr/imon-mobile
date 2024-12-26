import 'package:flutter/material.dart';

class AppStyling {
  static final List<Widget> items = <Widget>[
    const Icon(Icons.home, size: 30),
    const Icon(Icons.water, size: 30),
    const Icon(Icons.add, size: 30),
    const Icon(Icons.developer_board, size: 30),
    const Icon(Icons.settings, size: 30),
  ];

  static const Color buttonColor = Color.fromARGB(255, 94, 117, 170);
  static const Color backgColor = Color.fromARGB(255, 238, 253, 253);
  static const Color inputColor = Color.fromARGB(125, 0, 0, 0);
  static const Color headingColor = Color.fromARGB(255, 32, 57, 131);
  static const BorderRadius borderRad = BorderRadius.all(Radius.circular(12));
}
