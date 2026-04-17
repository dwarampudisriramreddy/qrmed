// lib/utils/web_download_util.non_web.dart
import 'dart:typed_data';
import 'package:flutter/material.dart'; // For BuildContext and SnackBar

void downloadFileWeb(BuildContext context, Uint8List bytes, String fileName) {
  // This function is a stub for non-web platforms.
  // The actual implementation is in web_download_util.web.dart
  debugPrint('⚠️ [STICKER] downloadFileWeb called on non-web platform. No action taken.');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Web download not supported on this platform.')),
  );
}
