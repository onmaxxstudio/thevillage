import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'Firebase is not configured for this platform yet.',
        ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnbaobLdWYLXY8pAbWKfWi8OvBlA28TGY',
    appId: '1:696766963629:web:05ca4af248f98628c08b24',
    messagingSenderId: '696766963629',
    projectId: 'the-village-d7af4',
    authDomain: 'the-village-d7af4.firebaseapp.com',
    storageBucket: 'the-village-d7af4.firebasestorage.app',
    measurementId: 'G-2NGZF58F2Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjXDKTYTMssHLilY8lPIYEniRtVixtXJ0',
    appId: '1:696766963629:android:4d98a7c11ca5901cc08b24',
    messagingSenderId: '696766963629',
    projectId: 'the-village-d7af4',
    storageBucket: 'the-village-d7af4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAp8qa48StRjsJhOS6Hcj7dRx30ScY5HWs',
    appId: '1:696766963629:ios:1006247bd659f8b4c08b24',
    messagingSenderId: '696766963629',
    projectId: 'the-village-d7af4',
    storageBucket: 'the-village-d7af4.firebasestorage.app',
    iosBundleId: 'com.onmaxxstudio.askthevillage',
  );

  static const googleIosClientId = '696766963629-btif0ntdiutqsedi51brrtecublecjpu.apps.googleusercontent.com';
  static const googleServerClientId = '696766963629-1es5dt4hc36hfis3mhfhmd2qr1vnvh26.apps.googleusercontent.com';
}
