import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:imon_app/pages/auth/signup_page.dart';
import 'package:imon_app/utils/style.dart';

import '../../services/auth_services.dart';
import '../home/home_nav.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: loginStatusChecker(context, (setState) {}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan dalam pengecekan status masuk'));
        }

        bool isLoggedIn = snapshot.data ?? false;

        if (isLoggedIn) {
          Future.delayed(Duration.zero, () {
            if (context.mounted){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeNav()),
              );
            }
          });
          return const SizedBox();
        }

        return Scaffold(
          backgroundColor: AppStyling.backgColor,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.75,
                  child: SvgPicture.asset(
                    'assets/images/landing_page.svg',
                    height: 250,
                    width: 250,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/IMON.png',
                        height: 400,
                        width: 400,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 150,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(AppStyling.buttonColor),
                          ),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 150,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(AppStyling.buttonColor),
                          ),
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
