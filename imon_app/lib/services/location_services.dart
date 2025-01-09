import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:imon_app/utils/style.dart';

class LocationPicker {
  static Future<List<Map<String, String>>> fetchProvinces() async {
    final url = Uri.parse(
        'https://ismannr.github.io/api-wilayah-indonesia/api/provinces.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => {
          "id": item["id"].toString(),
          "name": item["name"].toString(),
        })
            .toList()
            .cast<Map<String, String>>()
          ..sort((a, b) => a['name']!.compareTo(b['name']!));
      } else {
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Map<String, String>>> fetchCities(String provinceId) async {
    final url = Uri.parse(
        'https://ismannr.github.io/api-wilayah-indonesia/api/regencies/$provinceId.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => {
          "id": item["id"].toString(),
          "name": item["name"].toString(),
        })
            .toList()
            .cast<Map<String, String>>()
          ..sort((a, b) => a['name']!.compareTo(b['name']!));
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static void showProvinceDropdown(
      BuildContext context,
      List<Map<String, String>> provinces,
      Function(Map<String, String>) onSelected,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: provinces.length,
            itemBuilder: (context, index) {
              final province = provinces[index];
              return ListTile(
                title: Text(province['name'] ?? ''),
                onTap: () {
                  onSelected(province);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  static void showCityDropdown(
      BuildContext context,
      List<Map<String, String>> cities,
      Function(Map<String, String>) onSelected,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return ListTile(
                title: Text(city['name'] ?? ''),
                onTap: () {
                  onSelected(city);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class CustomDropdownField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final VoidCallback onTap;
  final FormFieldValidator<String>? validator;

  const CustomDropdownField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                borderSide: BorderSide(
                  color: AppStyling.buttonColor,
                  width: 1,
                ),
              ),
              labelStyle: const TextStyle(color: AppStyling.inputColor),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }
}
