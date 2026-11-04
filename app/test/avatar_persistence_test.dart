@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:ask_the_village/services/profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

Future<T> emulatorStep<T>(String name, Future<T> operation) =>
    operation.timeout(
      const Duration(seconds: 55),
      onTimeout: () {
        throw StateError('Avatar persistence test timed out during $name.');
      },
    );

Future<void> loadTestSdk() {
  final loaded = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = 'http://127.0.0.1:8765/avatar-firebase-sdk.js';
  script.addEventListener('load', ((web.Event _) => loaded.complete()).toJS);
  script.addEventListener(
    'error',
    ((web.Event _) {
      loaded.completeError(
        StateError('Could not load the local Firebase test SDK.'),
      );
    }).toJS,
  );
  web.document.head!.appendChild(script);
  return loaded.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'avatar fields persist through sign-out and reload in both profiles',
    () async {
      await emulatorStep('local SDK loading', loadTestSdk());
      FirebaseCoreWeb.registerWith(webPluginRegistrar);
      FirebaseAuthWeb.registerWith(webPluginRegistrar);
      FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
      SharedPreferences.setMockInitialValues({});
      await emulatorStep(
        'Firebase initialization',
        Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'fake-api-key',
            appId: '1:123:web:abc',
            messagingSenderId: '123',
            projectId: 'demo-village',
          ),
        ),
      );
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      await emulatorStep(
        'Auth emulator connection',
        auth.useAuthEmulator('127.0.0.1', 9099),
      );
      firestore.useFirestoreEmulator('127.0.0.1', 8080);
      const email = 'avatar-builder-test@example.test';
      const password = 'emulator-test-password';
      final account = await emulatorStep(
        'test member creation',
        auth.createUserWithEmailAndPassword(email: email, password: password),
      );
      final uid = account.user!.uid;
      final profiles = ProfileService();
      await emulatorStep(
        'test profile setup',
        profiles.ensureCurrentUserProfile(preferredUsername: 'avatar_test'),
      );
      await emulatorStep(
        'avatar save',
        profiles.updateAvatar(
          mode: 'avatar',
          key: 'plum',
          skin: 8,
          hair: 4,
          hairColor: 9,
          face: 2,
          eyes: 1,
          smile: 2,
          presentation: 2,
          facialHair: 3,
          mole: 4,
          nose: 1,
          brows: 2,
          glasses: 1,
          freckles: 2,
          eyeColor: 5,
        ),
      );

      await emulatorStep('sign-out', auth.signOut());
      await emulatorStep(
        'sign-in',
        auth.signInWithEmailAndPassword(email: email, password: password),
      );
      final profile = await emulatorStep(
        'profile reload',
        profiles.loadProfile(),
      );
      final appearance = {
        'avatarMode': profile.avatarMode,
        'avatarKey': profile.avatarKey,
        'avatarSkin': profile.avatarSkin,
        'avatarHair': profile.avatarHair,
        'avatarHairColor': profile.avatarHairColor,
        'avatarFace': profile.avatarFace,
        'avatarEyes': profile.avatarEyes,
        'avatarSmile': profile.avatarSmile,
        'avatarPresentation': profile.avatarPresentation,
        'avatarFacialHair': profile.avatarFacialHair,
        'avatarMole': profile.avatarMole,
        'avatarNose': profile.avatarNose,
        'avatarBrows': profile.avatarBrows,
        'avatarGlasses': profile.avatarGlasses,
        'avatarFreckles': profile.avatarFreckles,
        'avatarEyeColor': profile.avatarEyeColor,
      };
      const expected = {
        'avatarMode': 'avatar',
        'avatarKey': 'plum',
        'avatarSkin': 8,
        'avatarHair': 4,
        'avatarHairColor': 9,
        'avatarFace': 2,
        'avatarEyes': 1,
        'avatarSmile': 2,
        'avatarPresentation': 2,
        'avatarFacialHair': 3,
        'avatarMole': 4,
        'avatarNose': 1,
        'avatarBrows': 2,
        'avatarGlasses': 1,
        'avatarFreckles': 2,
        'avatarEyeColor': 5,
      };
      expect(profile.uid, uid);
      expect(appearance, expected);
      for (final collection in ['users', 'public_profiles']) {
        final snapshot = await firestore
            .collection(collection)
            .doc(uid)
            .get(const GetOptions(source: Source.server));
        for (final field in expected.entries) {
          expect(snapshot.data()?[field.key], field.value, reason: collection);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
