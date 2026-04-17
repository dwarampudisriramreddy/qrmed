import 'dart:typed_data';
import 'dart:html' as html;

class WebDownloadHelper {
  static void downloadFile(Uint8List bytes, String fileName) {
    final String mimeType = 'image/png';
    
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    
    html.document.body?.append(anchor);
    anchor.click();
    
    // Cleanup
    html.Url.revokeObjectUrl(url);
    anchor.remove();
  }
}
