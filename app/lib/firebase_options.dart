import 'package:firebase_core/firebase_core.dart';

/// This placeholder keeps the app buildable until the project owner runs
/// `flutterfire configure`. The FlutterFire CLI replaces this file with the
/// platform-specific, non-secret Firebase identifiers for Ask the Village.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase has not been configured. Run flutterfire configure.',
      );
}
