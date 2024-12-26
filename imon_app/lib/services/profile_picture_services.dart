import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imon_app/utils/style.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/debug.dart';

Future<void> editProfilePicture({
  required File currentImage,
  required Function(File) onImageCropped,
}) async {
  final CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: currentImage.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Edit Foto',
        toolbarColor: Colors.black,
        toolbarWidgetColor: Colors.white,
        hideBottomControls: true,
        lockAspectRatio: true,
        cropStyle: CropStyle.circle,
      ),
      IOSUiSettings(
        title: 'Edit Foto',
      ),
    ],
  );

  if (croppedFile != null) {
    onImageCropped(File(croppedFile.path));
  }
}

Future<void> deleteLocalProfilePicture() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final profilePicDir = '${appDir.path}/profile_pictures';

    final jpgFilePath = '$profilePicDir/profile_picture.jpg';
    final pngFilePath = '$profilePicDir/profile_picture.png';

    final jpgFile = File(jpgFilePath);
    if (await jpgFile.exists()) {
      await jpgFile.delete();
    }

    final pngFile = File(pngFilePath);
    if (await pngFile.exists()) {
      await pngFile.delete();
    }
  } catch (e) {
    debugMode('Terjadi masalah saat menghapus foto lokal: ${e.toString()}');
  }
}

Future<File?> getProfilePicture() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final profilePicDir = '${appDir.path}/profile_pictures';

    final jpgFilePath = '$profilePicDir/profile_picture.jpg';
    final pngFilePath = '$profilePicDir/profile_picture.png';

    final jpgFile = File(jpgFilePath);
    if (await jpgFile.exists()) {
      return jpgFile;
    }

    final pngFile = File(pngFilePath);
    if (await pngFile.exists()) {
      return pngFile;
    }
  } catch (e) {
    debugMode('Terjadi masalah saat memuat foto: $e');
  }
  return null;
}

Future<void> pickImage({
  required bool galleryImage,
  required Function(File) onImagePicked,
  required BuildContext context,
}) async {
  final ImagePicker picker = ImagePicker();

  try {
    final XFile? pickedFile = await picker.pickImage(
      source: galleryImage ? ImageSource.gallery : ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      final String fileExtension = pickedFile.path.split('.').last.toLowerCase();
      if (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'png') {
        onImagePicked(File(pickedFile.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format foto harus .jpg, .jpeg, atau .png'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terjadi masalah saat memilih gambar: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Widget actionButton({
  required BuildContext context,
  required String text,
  required VoidCallback onTap,
  Color color = AppStyling.buttonColor,
  Color textColor = Colors.white70,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: MediaQuery.of(context).size.width - 40,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

