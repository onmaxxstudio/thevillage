import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadCover({required String contentType}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw FirebaseException(plugin: 'firebase_storage', message: 'Sign in before uploading a photo.');

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      throw FirebaseException(plugin: 'firebase_storage', message: 'Please choose a photo smaller than 8 MB.');
    }

    final extension = _extension(picked.name);
    final path = 'admin_content/${user.uid}/$contentType/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = FirebaseStorage.instance.ref(path);
    final contentTypeHeader = extension == 'png' ? 'image/png' : extension == 'webp' ? 'image/webp' : 'image/jpeg';
    await ref.putData(bytes, SettableMetadata(contentType: contentTypeHeader));
    return ref.getDownloadURL();
  }

  String _extension(String name) {
    final ext = name.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'webp'}.contains(ext) ? ext : 'jpg';
  }
}
