import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:imon_app/services/aws_services.dart';
import 'package:imon_app/utils/style.dart';
import '../../utils/alert.dart';
import '../../services/location_services.dart';
import '../../services/auth_services.dart';
import '../../services/profile_picture_services.dart';
import '../../services/user_services.dart';
import '../auth/landing_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _profileData;
  Uint8List? localProfilePicture;
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final provinceController = TextEditingController();
  final businessNameController = TextEditingController();
  final businessDescController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    provinceController.dispose();
    businessNameController.dispose();
    businessDescController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _cities = [];
  String? selectedCity;
  String? selectedProvince;
  List<Map<String, String>> _provinces = [];
  bool isEditable = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _profileData = fetchUserProfile();
    localProfilePicture = await getProfilePicture();
    loadProvinces();
    setState(() {});
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
      if(context.mounted){
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
      }
  }

  Future<Map<String, dynamic>> _updateProfile() async {
    final updateProfileUrl = Uri.parse('${getBaseUrl()}/user');

    try {
      final headers = await getHeaders();
      final body = json.encode({
        'phone': phoneController.text,
        'address': addressController.text,
        'city': cityController.text,
        'province': provinceController.text,
        'business_name': businessNameController.text,
        'business_desc': businessDescController.text,
        'password': passwordController.text,
        'confirm_password': confirmPasswordController.text,
      });

      final response = await http.put(
        updateProfileUrl,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Gagal mengubah profil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyling.backgColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Terjadi kesalahan: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Data profil tidak ditemukan"));
          }

          final data = snapshot.data!;
          final profilePictureUrl = data['profilePictureUrl'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppStyling.backgColor,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  expandedHeight: 250,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Center(
                      child: GestureDetector(
                        onTap: () async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.black.withOpacity(0.7),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          ),
                                          InteractiveViewer(
                                            child: localProfilePicture != null
                                                ? Image.memory(
                                              localProfilePicture!,
                                              fit: BoxFit.contain,
                                            )
                                                : const Image(
                                              image: AssetImage('assets/images/default_profile.png'),
                                              fit: BoxFit.contain,
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(20.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    actionButton(
                                                      context: context,
                                                      text:
                                                          'Unggah Foto Dari Kamera',
                                                      onTap: () {
                                                        uploadProfilePicture(
                                                            context, false, () {
                                                          setState(() {
                                                            _profileData =
                                                                fetchUserProfile();
                                                          });
                                                        });
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                    actionButton(
                                                      context: context,
                                                      text:
                                                          'Unggah Foto Dari Galeri',
                                                      onTap: () {
                                                        uploadProfilePicture(
                                                            context, true, () {
                                                          setState(() {
                                                            _profileData =
                                                                fetchUserProfile();
                                                          });
                                                        });
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                    actionButton(
                                                      context: context,
                                                      text: 'Hapus Foto Profil',
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                        deleteProfilePicture(
                                                            () {
                                                          setState(() {
                                                            _profileData =
                                                                fetchUserProfile();
                                                          });
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                    actionButton(
                                                      context: context,
                                                      text: 'Kembali',
                                                      color: Colors.white,
                                                      textColor: AppStyling
                                                          .buttonColor,
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                          setState(
                                            () {
                                              _profileData = fetchUserProfile();
                                            },
                                          );
                                        },
                                        child: const Text("Ubah Foto Profil"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: CircleAvatar(
                          radius: 128,
                          backgroundColor: Colors.transparent,
                          child: profilePictureUrl != null &&
                                  profilePictureUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const Image(
                                        image: AssetImage(
                                            'assets/images/default_profile.png'),
                                        fit: BoxFit.cover,
                                        width: 256,
                                        height: 256,
                                      ),
                                      FutureBuilder<Uint8List?>(
                                        future: getProfilePicture(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          } else if (snapshot.hasError) {
                                            return const Icon(
                                              Icons.error,
                                              size: 100,
                                              color: Colors.red,
                                            );
                                          } else if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return Container(
                                              color: Colors.white,
                                              child: Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                width: 256,
                                                height: 256,
                                              ),
                                            );
                                          } else {
                                            return const Image(
                                              image: AssetImage(
                                                  'assets/images/default_profile.png'),
                                              fit: BoxFit.cover,
                                              width: 256,
                                              height: 256,
                                            );
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                )
                              : const Image(
                                  image: AssetImage(
                                      'assets/images/default_profile.png'),
                                  fit: BoxFit.cover,
                                  width: 256,
                                  height: 256,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          data['name'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['email'] ?? 'N/A',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          isEditable = !isEditable;
                                          if (!isEditable) {}
                                        });
                                      },
                                      child: const Icon(
                                        Icons.edit,
                                        color: AppStyling.buttonColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                    "Jenis Kelamin", data['gender'] ?? 'N/A'),
                                _buildDetailRow(
                                    "Tanggal Lahir",
                                    data['birth_date']?.substring(0, 10) ??
                                        'N/A'),
                                _buildEditableDetailRow(
                                    "Alamat",
                                    data['address'] ?? 'N/A',
                                    addressController),
                                _buildEditableDetailRow("Nomor Telepon",
                                    data['phone'] ?? 'N/A', phoneController),
                                _buildDropdownDetailRow(
                                  title: 'Provinsi',
                                  value: provinceController.text.isNotEmpty
                                      ? provinceController.text
                                      : data['province'] ?? 'N/A',
                                  controller: provinceController,
                                  onTap: () {
                                    LocationPicker.showProvinceDropdown(
                                      context,
                                      _provinces,
                                      (province) {
                                        if (province['id'] !=
                                            selectedProvince) {
                                          setState(() {
                                            selectedProvince = province['id'];
                                            provinceController.text =
                                                province['name']!;
                                            selectedCity = null;
                                            cityController.clear();
                                            _cities = [];
                                            print("object");
                                          });
                                          loadCities(province['id']!);
                                        }
                                      },
                                    );
                                  },
                                ),
                                _buildDropdownDetailRow(
                                  title: 'Kota',
                                  value: cityController.text.isNotEmpty
                                      ? cityController.text
                                      : data['city'] ?? 'N/A',
                                  controller: cityController,
                                  onTap: () {
                                    LocationPicker.showCityDropdown(
                                      context,
                                      _cities,
                                      (city) {
                                        setState(() {
                                          selectedCity = city['id'];
                                          cityController.text = city['name']!;
                                        });
                                      },
                                    );
                                  },
                                ),
                                _buildEditableDetailRow(
                                    "Nama Bisnis",
                                    data['business_name'] ?? 'N/A',
                                    businessNameController),
                                _buildEditableDetailRow(
                                    "Deskripsi Bisnis",
                                    data['business_desc'] ?? 'N/A',
                                    businessDescController),
                                if (isEditable)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppStyling.buttonColor),
                                      onPressed: () async {
                                        if (selectedProvince != null &&
                                            selectedCity == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Harap pilih Provinsi dan Kota yang valid')),
                                          );
                                          return;
                                        }

                                        if (addressController.text.length < 5 &&
                                            addressController.text.isNotEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Alamat tidak bisa kurang dari 5 karakter')),
                                          );
                                          return;
                                        }

                                        if ((phoneController.text.length < 10 ||
                                                phoneController.text.length >
                                                    14) &&
                                            addressController.text.isNotEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Nomor telepon harus 10 sampai 14 digit')),
                                          );
                                          return;
                                        }

                                        if (businessNameController
                                                    .text.length <=
                                                2 &&
                                            businessNameController
                                                .text.isNotEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Nama bisnis tidak bisa kurang dari dua huruf')),
                                          );
                                          return;
                                        }

                                        if (businessDescController
                                                    .text.length <=
                                                2 &&
                                            businessDescController
                                                .text.isNotEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Deskripsi bisnis tidak bisa kurang dari dua huruf')),
                                          );
                                          return;
                                        }

                                        try {
                                          await _updateProfile();
                                          if(context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Profil berhasil diperbarui'),
                                              ),
                                            );
                                          }

                                          final updatedData =
                                              await fetchUserProfile();
                                          setState(() {
                                            _profileData =
                                                Future.value(updatedData);
                                            isEditable = false;
                                          });
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Gagal memperbarui profil: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text(
                                        'Simpan',
                                        style: TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showChangePasswordDialog(
                                context); // Trigger the dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyling.buttonColor,
                          ),
                          child: const Text(
                            'Ganti Password',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            showAlert(
                              context,
                              title: "Konfirmasi Keluar",
                              message: "Apakah anda yakin untuk keluar?",
                              onConfirm: () async {
                                await logout();
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LandingPage()),
                                  );
                                }
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyling.buttonColor),
                          child: const Text(
                            'Keluar',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailRow(
      String title, String value, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          isEditable
              ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: value,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
        ],
      ),
    );
  }

  Widget _buildDropdownDetailRow({
    required String title,
    required String value,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          isEditable
              ? GestureDetector(
                  onTap: onTap,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: value.isEmpty ? "Pilih $title" : value,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon pilih $title';
                        }
                        return null;
                      },
                    ),
                  ),
                )
              : Text(
                  value.isEmpty ? "Belum dipilih" : value,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ganti Password"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password Baru'),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password Baru'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text == confirmPasswordController.text) {
                  await _updateProfile();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password berhasil diganti')),
                    );
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords tidak sama')),
                  );
                }
              },
              child: const Text('Ganti Password'),
            ),
          ],
        );
      },
    );
  }
}
