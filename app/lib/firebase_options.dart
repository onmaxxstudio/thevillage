import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase Web has not been configured yet.');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
          'Firebase is not configured for this platform yet.',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjXDKTYTMssHLilY8lPIYEniRtVixtXJ0',
    appId: '1:696766963629:android:4d98a7c11ca5901cc08b24',
    messagingSenderId: '696766963629',
    projectId: 'the-village-d7af4',
    storageBucket: 'the-village-d7af4.firebasestorage.app',
  );
}
