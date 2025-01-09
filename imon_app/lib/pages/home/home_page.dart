import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imon_app/models/validation_data.dart';
import 'package:imon_app/services/pond_services.dart';
import 'package:imon_app/utils/style.dart';
import '../../services/device_service.dart';
import '../../services/user_services.dart';
import 'article_page.dart';
import 'home_nav.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  List<dynamic> articles = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadArticles();
  }

  Future<void> loadUserData() async {
    final data = await fetchUserData();
    if (mounted) {
      setState(() {
        userData = data;
      });
    }
  }

  Future<void> loadArticles() async {
    final String jsonString =
        await rootBundle.loadString('assets/articles/body/articles.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    if (mounted) {
      setState(() {
        articles = jsonData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = (userData?['name'] ?? "N/A").split(' ')[0];
    final String businessName = userData?['business_name'] ?? "N/A";
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ValueListenableBuilder<Uint8List?>(
                    valueListenable: profilePictureNotifier,
                    builder: (context, profilePic, child) {
                      if (profilePic == null) {
                        return const Image(
                          image:
                              AssetImage('assets/images/default_profile.png'),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        );
                      } else {
                        return ClipOval(
                          child: Image.memory(
                            profilePic,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Halo, $userName!',
                    style: const TextStyle(
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    businessName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppStyling.buttonColor,
                        ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: validationNotifier,
                    builder:
                        (BuildContext context, bool isValid, Widget? child) {
                      String pondStatus = "Sedang Dilakukan Pengecekan";
                      IconData icon = Icons.help_outline;
                      Color iconColor = Colors.grey;

                      if (isValid) {
                        pondStatus = "Semua Sistem Normal";
                        icon = Icons.check_circle;
                        iconColor = Colors.green;
                      } else {
                        pondStatus = "Segera Cek Kolam Anda!";
                        icon = Icons.warning;
                        iconColor = Colors.deepOrangeAccent;
                      }
                      return Column(
                        children: [
                          Center(
                              child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationPage(),
                                ),
                              ).then((_) {
                                hasValidationData();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(30, 2, 30, 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color.fromARGB(255, 219, 229, 255),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    color: iconColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    pondStatus,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(height: 26),
                          Center(
                            child: SizedBox(
                              height: 120, // Set a specific height for the row
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Jumlah Kolam',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FutureBuilder<int>(
                                          future: PondServices.countPonds(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color.fromARGB(
                                                        255, 157, 181, 255),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: const Text(
                                                  '0',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color.fromARGB(
                                                        255, 157, 181, 255),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${snapshot.data ?? 0}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const VerticalDivider(
                                    color: Colors.black,
                                    thickness: 1,
                                    width: 30,
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Jumlah Perangkat',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FutureBuilder<int>(
                                          future: DeviceService.countDevices(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color.fromARGB(
                                                        255, 157, 181, 255),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: const Text(
                                                  '0',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color.fromARGB(
                                                        255, 157, 181, 255),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${snapshot.data ?? 0}',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Artikel',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 500,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 0.7,
                ),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailPage(
                            title: article['title']!,
                            imagePath: article['imagePath']!,
                            body: article['body']!,
                            imgSrc: article['image_source']!,
                            src: article['src']!,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            article['imagePath']!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              article['title']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              article['description']!,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
