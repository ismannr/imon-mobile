import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:imon_app/pages/home/devices_page.dart';
import 'package:imon_app/services/auth_services.dart';
import 'package:imon_app/pages/home/ponds_page.dart';
import 'package:imon_app/pages/home/profile_page.dart';
import 'package:imon_app/utils/style.dart';
import '../../models/ponds_data.dart';
import '../../models/validation_data.dart';
import '../../services/monitoring_data_service.dart';
import '../../services/scheduler_service.dart';
import '../../utils/alert.dart';
import '../../services/aws_services.dart';
import '../../services/pond_services.dart';
import '../../utils/timezone.dart';
import 'home_page.dart';

ValueNotifier<File?> profilePictureNotifier = ValueNotifier<File?>(null);

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  bool isLoggedIn = false;
  bool showFAB = false;
  int index = 0;
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
    getMonitor();
    downloadProfilePicture();
    startService();
    checkValidation();
    startValidationCheck();
    loadPonds();
  }

  Future<void> loadPonds() async {
    try {
      final pondData = await PondServices.fetchPonds();
      setState(() {
        ponds = pondData;
      });
    } catch (e) {
      showErrorAlert(context, '$e');
    }
  }

  Future<void> checkValidation() async {
    await hasValidationData();
  }

  void startValidationCheck() {
    _validationTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await checkValidation();
      if (mounted){
        setState(() {});
      }
    });
  }

  Future<void> downloadProfilePicture() async {
    File? profilePic = await downloadAndSaveProfilePicture();
    profilePictureNotifier.value = profilePic;
  }


  Future<void> getMonitor() async {
    await getAllDeviceMonitorData(aDayInterval(), getCurrentDateTime());
  }

  final List<Widget> items = <Widget>[
    const Icon(Icons.home, size: 30),
    const Icon(Icons.water, size: 30),
    const Icon(Icons.add, size: 30),
    const Icon(Icons.developer_board, size: 30),
    const Icon(Icons.settings, size: 30),
  ];

  final List<Widget?> screens = [
    const HomePage(),
    const PondsPage(),
    null,
    const DevicesPage(),
    const ProfilePage(),
  ];

  Future<void> _promptCreatePond(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Kolam'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Masukkan nama kolam'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _createPond(result);
    }
  }

  Future<void> _registerDevice(BuildContext context, String deviceId,
      String deviceName, String groupId) async {
    if (deviceId.isEmpty || deviceName.isEmpty) {
      showAlert(context,
          title: 'Terjadi Kesalahan',
          message: 'Masukkan nama dan id dari perangkat IMON');
    }

    final url = Uri.parse('${getBaseUrl()}/device/register/$deviceId');
    final headers = await getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'name': deviceName, 'group_id': groupId}),
      );

      if (context.mounted) {
        if (response.statusCode == 200) {
          showAlert(context,
              title: 'Sukses', message: 'Perangkat berhasil didaftarkan');
        } else {
          String errorMessage = 'Gagal mendaftarkan perangkat';
          if (response.body.isNotEmpty) {
            final responseStatus = json.decode(response.statusCode as String);
            errorMessage = '$errorMessage (status: $responseStatus)';
          }
          showAlert(context, title: 'Error', message: errorMessage);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, title: 'Terjadi Kesalahan', message: '$e');
      }
    }
  }

  Future<void> _promptRegisterDevice(BuildContext context) async {
    final pondData = await PondServices.fetchPonds();

    if (pondData.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Tidak ada kolam"),
            content:
                const Text("Tambahkan kolam untuk mendaftarkan perangkat IMON"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Daftar"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pondData.length,
              itemBuilder: (context, index) {
                final pond = pondData[index];
                return ListTile(
                  title: Text(pond['group_name']),
                  subtitle:
                      Text("Jumlah perangkat: ${pond['number_of_device']}"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _promptEnterDeviceDetails(context, pond['id'] ?? 'N/A',
                        pond['group_name'] ?? 'N/A');
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptEnterDeviceDetails(
      BuildContext context, String pondId, String pondName) async {
    final TextEditingController deviceNameController = TextEditingController();
    final TextEditingController deviceIdController = TextEditingController();

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Masukkan Detail Perangkat"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deviceNameController,
                decoration: const InputDecoration(
                  labelText: "Nama perngkat",
                ),
              ),
              TextField(
                controller: deviceIdController,
                decoration: const InputDecoration(
                  labelText: "ID perangkat",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Kembali"),
            ),
            TextButton(
              onPressed: () {
                final deviceName = deviceNameController.text;
                final deviceId = deviceIdController.text;

                if (deviceName.isNotEmpty && deviceId.isNotEmpty) {
                  // Call the register device function
                  _registerDevice(context, deviceId, deviceName, pondId);
                  Navigator.of(context).pop();
                } else {
                  // Show alert if fields are empty
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Terjadi kesalahan"),
                        content: const Text("Masukkan nama dan ID perangkat"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text("Daftar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createPond(String pondName) async {
    final url = Uri.parse('${getBaseUrl()}/group/create');
    try {
      final headers = await getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'group_name': pondName,
        }),
      );

      if (response.statusCode == 200) {
        PondServices.fetchPonds();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kolam berhasil ditambahkan')),
        );
      }
    } catch (error) {
      showErrorAlert(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return WillPopScope(
      onWillPop: () async {
        isLoggedIn = await loginStatusChecker(context, setState);
        if (isLoggedIn) {
          SystemNavigator.pop();
          return false;
        } else {
          if (isLoggedIn == false) {
            if (context.mounted) {
              sessionTimeout(context);
            }
            return false;
          }
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: AppStyling.backgColor,
        primary: false,
        body: SafeArea(child: screens[index] ?? Container()),
        floatingActionButton: Stack(
          children: [
            if (showFAB)
              Positioned(
                bottom: 0,
                left: MediaQuery.of(context).size.width / 2 - 77,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _promptCreatePond(context);
                        },
                        icon: const Icon(Icons.water,
                            color: AppStyling.buttonColor, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            if (showFAB)
              Positioned(
                bottom: 0,
                left: MediaQuery.of(context).size.width / 2 + 20,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _promptRegisterDevice(context);
                        },
                        icon: const Icon(Icons.developer_board,
                            color: AppStyling.buttonColor, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: AppStyling.backgColor,
          items: items,
          index: index,
          onTap: (idx) async {
            isLoggedIn = await loginStatusChecker(context, setState);
            if (!isLoggedIn) {
              if (context.mounted) {
                sessionTimeout(context);
              }
              return;
            }

            setState(() {
              if (idx == 2 && index == 4) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pemberitahuan'),
                      content: const Text(
                          'Mohon keluar dari profil anda untuk menambahkan kolam atau perangkat'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
                return;
              }

              if (idx == 2) {
                showFAB = !showFAB;
              } else {
                index = idx;
                showFAB = false;
              }
            });
          },
        ),
      ),
    );
  }
}
