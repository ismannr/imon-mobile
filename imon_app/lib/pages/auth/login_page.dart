import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:imon_app/utils/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../services/auth_services.dart';
import 'forget_page.dart';
import '../home/home_nav.dart';
import 'landing_page.dart';

const Color backgColor = Color.fromARGB(255, 238, 253, 253);
const Color inputColor = Color.fromARGB(125, 0, 0, 0);
const borderRad = BorderRadius.all(Radius.circular(12));
const Color buttonColor = Color.fromARGB(255, 94, 117, 170);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text;
      String password = _passwordController.text;

      Map<String, String> requestBody = {
        'email': email.toLowerCase(),
        'password': password,
      };

      var url = Uri.parse('${getBaseUrl()}/login');
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
          String? cookie = response.headers['set-cookie'];
          if (cookie != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cookie', cookie);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Berhasil Masuk'),
                  ],
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeNav()),
            );
          }
        } else if (response.statusCode == 400) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Password atau email salah'),
                ],
              ),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
        else {
          var errorResponse = jsonDecode(response.statusCode as String);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(errorResponse['message'] ?? 'Password atau email salah'),
                ],
              ),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        debugMode(e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Telah terjadi kesalahan'),
                ],
              ),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
                    builder: (context) => const LandingPage(),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/images/dualcircle.svg',
              height: 250,
              width: 250,
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
                        'Selamat datang!',
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
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Password',
                              labelStyle: TextStyle(color: inputColor),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: borderRad,
                                borderSide:
                                BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: borderRad,
                                borderSide: BorderSide(
                                  color: buttonColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            obscureText: true,
                            cursorColor: inputColor,
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ForgetPage()),
                                );
                              },
                              child: const Text(
                                'Lupa Password',
                                style: TextStyle(
                                  color: buttonColor,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                          onPressed: _login,
                          style: ButtonStyle(
                            backgroundColor:
                            WidgetStateProperty.all(buttonColor),
                          ),
                          child: const Text(
                            'Masuk',
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


