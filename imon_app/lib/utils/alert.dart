import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showAlert(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmText,
  VoidCallback? onConfirm,
  VoidCallback? onClose,
  bool dismissible = true,
}) {
  showDialog(
    context: context,
    barrierDismissible: dismissible,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onClose != null) {
                onClose();
              }
            },
            child: const Text('Tutup'),
          ),
          if (onConfirm != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(confirmText ?? 'Konfirmasi',
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      );
    },
  );
}

void showErrorAlert(BuildContext context, String e) {
  showAlert(context,
      title: 'Terjadi masalah',
      message: 'Telah terjadi masalah, silahkan hubungi kami');
  if (kDebugMode) {
    print('Terjadi masalah: $e');
  }
}

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );
}

