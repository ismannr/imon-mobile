import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:imon_app/utils/style.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/location_services.dart';
import '../../services/auth_services.dart';
import 'landing_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescController = TextEditingController();

  bool _isSubmitted = false;
  List<Map<String, String>> _cities = [];
  String? _selectedCity;
  String? _selectedProvince;
  List<Map<String, String>> _provinces = [];
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    loadProvinces();
  }

  Future<void> loadProvinces() async {
    try {
      final provinces = await LocationPicker.fetchProvinces();
      setState(() {
        _provinces = provinces;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> loadCities(String provinceId) async {
    try {
      final cities = await LocationPicker.fetchCities(provinceId);
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != DateTime.now()) {
      final age = DateTime.now().year - pickedDate.year;
      if (age < 17 ||
          (age == 17 &&
              DateTime.now()
                  .isBefore(pickedDate.add(const Duration(days: 365 * 17))))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna harus diatas 17 tahun')),
        );
      } else {
        setState(() {
          _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        });
      }
    }
  }

  void _signUp() async {
    setState(() {
      _isSubmitted = true;
    });

    if (_formKey.currentState!.validate() && _selectedProvince != null) {
      var requestBody = {
        "name": _nameController.text,
        "email": _emailController.text,
        "gender": _selectedGender,
        "dob": _dobController.text,
        "password": _passwordController.text,
        "confirm_password": _confirmPasswordController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        "city": _cityController.text,
        "province": _provinceController.text,
        "business_name": _businessNameController.text,
        "business_desc": _businessDescController.text,
      };

      var url = Uri.parse('${getBaseUrl()}/sign-up');

      try {
        var response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendaftaran berhasil!')),
          );
          Navigator.pop(context);
        } else if (response.statusCode == 400) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Pengguna sudah terdaftar menggunakan email dan/atau nomor ini'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Kembali',
                textColor: Colors.white,
                onPressed: () {
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pendaftaran gagal: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyling.backgColor,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/images/dualcircle.svg',
              height: 250,
              width: 250,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        child: SvgPicture.asset(
                          'assets/images/back.svg',
                          height: 35,
                          width: 35,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LandingPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.only(top: 75.0, bottom: 16.0),
                      child: const Text(
                        "Memulai",
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: AppStyling.headingColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Nama",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 3) {
                            return 'Masukkan nama anda';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Email",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: AppStyling.inputColor,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan email anda';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Masukkan email yang valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Jenis Kelamin",
                            style: TextStyle(color: AppStyling.inputColor, fontSize: 16),
                          ),
                          RadioListTile<String>(
                            title: const Text('Laki-Laki'),
                            value: 'Male',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Perempuan'),
                            value: 'Female',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                          if (_isSubmitted && _selectedGender == null)
                            const Text(
                              'Pilih jenis kelamin anda',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide(
                                  color: AppStyling.buttonColor,
                                  width: 2,
                                ),
                              ),
                              labelText: "Tanggal Lahir (YYYY-MM-DD)",
                              labelStyle: TextStyle(color: AppStyling.inputColor),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Masukkan tanggal lahir anda';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          LocationPicker.showProvinceDropdown(
                            context,
                            _provinces,
                                (province) {
                              setState(() {
                                _selectedProvince = province['id'];
                                _provinceController.text = province['name']!;
                              });
                              loadCities(province['id']!);
                            },
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _provinceController,
                            decoration: const InputDecoration(
                              labelText: "Provinsi",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide(
                                  color: AppStyling.buttonColor,
                                  width: 1,
                                ),
                              ),
                              labelStyle: TextStyle(color: AppStyling.inputColor),
                            ),
                            validator: (value) {
                              if (_selectedProvince == null ||
                                  _selectedProvince!.isEmpty) {
                                return 'Masukkan provinsi anda';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedProvince == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pilih provinsi terlebih dahulu')));
                            return;
                          }
                          LocationPicker.showCityDropdown(
                            context,
                            _cities,
                                (city) {
                              setState(() {
                                _selectedCity = city['id'];
                                _cityController.text = city['name']!;
                              });
                            },
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Kota",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                borderSide: BorderSide(
                                  color: AppStyling.buttonColor,
                                  width: 1,
                                ),
                              ),
                              labelStyle: TextStyle(color: AppStyling.inputColor),
                            ),
                            validator: (value) {
                              if (_selectedCity == null ||
                                  _selectedCity!.isEmpty) {
                                return 'Masukkan kota anda';
                              }
                              return null;
                            },
                            controller: TextEditingController(
                              text: _selectedCity != null
                                  ? _cities.firstWhere((city) =>
                                      city['id'] == _selectedCity)['name']
                                  : '',
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Password",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan password anda';
                          }
                          if (value.length < 8) {
                            return 'Password harus 8 karakter atau lebih';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Konfirmasi Password",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password anda';
                          }
                          if (value != _passwordController.text) {
                            return 'Password tidak sama';
                          }
                          return null;
                        },
                      ),
                    ), // Phone Field
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Nomor Telepon",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan nomor telepon anda';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Alamat",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan alamat anda';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Nama Bisnis",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan nama bisnis anda';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextFormField(
                        controller: _businessDescController,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppStyling.borderRad,
                            borderSide: BorderSide(
                              color: AppStyling.buttonColor,
                              width: 2,
                            ),
                          ),
                          labelText: "Deskripsi Bisnis",
                          labelStyle: TextStyle(color: AppStyling.inputColor),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan deskripsi bisnis anda';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(AppStyling.buttonColor),
                            ),
                            onPressed: _signUp,
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
