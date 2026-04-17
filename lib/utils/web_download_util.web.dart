// lib/utils/web_download_util.web.dart
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart'; // For ScaffoldMessenger, if needed

void downloadFileWeb(BuildContext context, Uint8List bytes, String fileName) {
  try {
    // Create a blob from the bytes
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create a temporary anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click(); // Simulate a click to trigger download

    // Revoke the object URL to free up memory
    html.Url.revokeObjectUrl(url);
    
    // Using ScaffoldMessenger from the context passed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download initiated for: $fileName')),
    );
    debugPrint('✅ [STICKER] Web download initiated for: $fileName');
  } catch (e) {
    debugPrint('❌ [STICKER] Web download failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error initiating web download: $e')),
    );
  }
}
