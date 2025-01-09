import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:imon_app/pages/home/home_nav.dart';
import 'package:imon_app/utils/debug.dart';
import 'package:imon_app/services/profile_picture_services.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_services.dart';

Future<File?> downloadAndSaveProfilePicture() async {
  final pictureUrl = Uri.parse('${getBaseUrl()}/user/profile-picture');
  try {
    final headers = await getHeaders();
    final pictureResponse = await http.get(pictureUrl, headers: headers);

    if (pictureResponse.statusCode == 200) {
      String profilePictureUrl = json.decode(pictureResponse.body)['data'];

      final response = await http.get(Uri.parse(profilePictureUrl));

      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final profilePicDir = Directory('${appDir.path}/profile_pictures');
        if (!await profilePicDir.exists()) {
          await profilePicDir.create(recursive: true);
        }
        String extension =
        response.headers['content-type'] == 'image/png' ? 'png' : 'jpg';
        final filePath = '${profilePicDir.path}/profile_picture.$extension';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return file;
      } else if (response.statusCode == 204) {
        debugMode('No profile picture available.');
        return null;
      } else {
        debugMode(
            'Failed to download image. Status code: ${response.statusCode}');
        return null;
      }
    } else {
      debugMode(
          'Failed to get profile picture URL. Status code: ${pictureResponse.statusCode}');
      return null;
    }
  } catch (e) {
    debugMode(e.toString());
    return null; // Return null on exception
  }
}


Future<void> deleteProfilePicture(Function onDeletionComplete) async {
  final deletePictureUrl =
      Uri.parse('${getBaseUrl()}/user/profile-picture/delete');
  try {
    final headers = await getHeaders();
    final response = await http.get(deletePictureUrl, headers: headers);

    if (response.statusCode == 200) {
      final String s3Url = json.decode(response.body)['data'];
      final deleteResponse = await http.delete(Uri.parse(s3Url));

      if (deleteResponse.statusCode == 204) {
        await deleteLocalProfilePicture();
        profilePictureNotifier.value = null;
        onDeletionComplete();
      } else {
        if (kDebugMode) {
          print('Failed to delete the profile picture from S3. '
              'Status Code: ${deleteResponse.statusCode}, Body: ${deleteResponse.body}');
        }
      }
    } else {
      if (kDebugMode) {
        print('Failed to get the S3 URL. '
            'Status Code: ${response.statusCode}, Body: ${response.body}');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during profile picture deletion: $e');
    }
  }
}

Future<void> uploadProfilePicture(BuildContext context, bool isFromGallery, Function() onUploadComplete) async {
  try {
    await pickImage(
      galleryImage: isFromGallery,
      context: context,
      onImagePicked: (File pickedImage) async {

        await editProfilePicture(
          currentImage: pickedImage,
          onImageCropped: (File croppedImage) async {
            final String ext = croppedImage.path.split('.').last.toLowerCase();

            final Map<String, String> requestBody = {"file_ext": '.$ext'};

            final pictureUrl = Uri.parse('${getBaseUrl()}/user/profile-picture/upload');
            final headers = await getHeaders();

            final pictureResponse = await http.put(
              pictureUrl,
              headers: headers,
              body: jsonEncode(requestBody),
            );

            if (pictureResponse.statusCode == 200) {
              String profilePictureUrl = json.decode(pictureResponse.body)['data'];

              final imageBytes = await croppedImage.readAsBytes();

              String contType = '';
              if (ext == "png") {
                contType = 'image/png';
              } else if (ext == "jpg" || ext == "jpeg") {
                contType = 'image/jpeg';
              }

              final uploadResponse = await http.put(
                Uri.parse(profilePictureUrl),
                headers: {
                  ...headers,
                  'Content-Type': contType,
                },
                body: imageBytes,
              );

              if (uploadResponse.statusCode == 200) {
                final appDir = await getApplicationDocumentsDirectory();
                final profilePicDir = Directory('${appDir.path}/profile_pictures');
                if (!await profilePicDir.exists()) {
                  await profilePicDir.create(recursive: true);
                }
                final filePath = '${profilePicDir.path}/profile_picture.$ext';

                final file = File(filePath);
                await file.writeAsBytes(imageBytes);
                profilePictureNotifier.value = imageBytes;
                onUploadComplete();
              } else if (uploadResponse.statusCode == 204) {
                debugMode('No content to upload.');
              } else {
                debugMode(
                    'Failed to upload image. Status code: ${uploadResponse.statusCode}');
              }
            } else {
              debugMode(
                  'Failed to upload profile picture URL. Status code: ${pictureResponse.statusCode}');
            }
          },
        );
      },
    );
  } catch (e) {
    debugMode('Error during upload: $e');
  }
}


