import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:imon_app/pages/auth/landing_page.dart';
import 'package:imon_app/utils/debug.dart';
import 'login_page.dart';
import '../../services/auth_services.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});

  @override
  State<ForgetPage> createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _forget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text;

      Map<String, String> requestBody = {
        'email': email,
      };

      var url = Uri.parse('${getBaseUrl()}/forgot-password');
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mohon cek email anda')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LandingPage()),
            );
          }
        } else {
          if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permintaan lupa password gagal')),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terjadi kesalahan')),
          );
        }
        debugMode(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgColor,
      body: Stack(
        children: [
          Positioned(
            top: 35,
            left: 10,
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
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: const Text(
                        'LUPA PASSWORD',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 74, 106, 169),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            borderRadius: borderRad,
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: borderRad,
                              borderSide: BorderSide(
                                color: buttonColor,
                                width: 2,
                              )),
                          labelText: "Email",
                          labelStyle: TextStyle(color: inputColor),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: inputColor,
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
                    const SizedBox(height: 32),
                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: 150,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _forget,
                          style: ButtonStyle(
                            backgroundColor:
                            WidgetStateProperty.all(buttonColor),
                          ),
                          child: const Text(
                            'KIRIM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
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
