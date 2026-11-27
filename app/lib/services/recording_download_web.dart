// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveRecording(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'video/mp4');
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final anchor = html.AnchorElement(href: url)..download = filename;
    anchor.click();
  } finally {
    Future<void>.delayed(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
  }
}
