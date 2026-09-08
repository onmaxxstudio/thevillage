import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'profile_service.dart';

class AuthService {
  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw const AuthSetupException(
        'Sign-in is not connected yet. Run flutterfire configure and enable '
        'the sign-in provider in Firebase.',
      );
    }
    return FirebaseAuth.instance;
  }

  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await ProfileService().ensureCurrentUserProfile();
    return credential;
  }

  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await ProfileService().ensureCurrentUserProfile(
      preferredUsername: name,
    );
    return credential;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  bool _googleInitialized = false;

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      // A full-page redirect is more reliable than a popup in iPhone/iPad
      // Safari and when the app is hosted on GitHub Pages.
      await _auth.signInWithRedirect(provider);
      return;
    }

    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? DefaultFirebaseOptions.googleIosClientId
            : null,
        serverClientId: DefaultFirebaseOptions.googleServerClientId,
      );
      _googleInitialized = true;
    }
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    await ProfileService().ensureCurrentUserProfile();
  }

  Future<UserCredential> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await ProfileService().ensureCurrentUserProfile();
    return credential;
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  String _promiseKey(String uid) => 'village_promise_accepted_$uid';

  Future<bool> hasAcceptedVillagePromise() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_promiseKey(user.uid)) ?? false;
  }

  Future<void> acceptVillagePromise() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthSetupException('Please sign in before accepting the promise.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_promiseKey(user.uid), true);
  }

  Future<void> signOut() => _auth.signOut();

  static String messageFor(Object error) {
    if (error is AuthSetupException) return error.message;
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' =>
          'That email or password is incorrect.',
        'email-already-in-use' =>
          'An account already exists for that email. Try signing in.',
        'weak-password' => 'Use a stronger password with at least 6 characters.',
        'too-many-requests' =>
          'Too many attempts. Please wait a moment and try again.',
        'popup-closed-by-user' || 'canceled-popup-request' =>
          'Sign-in was canceled.',
        'unauthorized-domain' =>
            'This website must be added to Firebase Authorized domains.',
        'operation-not-allowed' =>
            'This sign-in option must be enabled in Firebase Authentication.',
        'network-request-failed' =>
            'Firebase could not connect. Check your internet connection and try again.',
        'account-exists-with-different-credential' =>
          'That email already uses a different sign-in method.',
        _ => error.message ?? 'We could not sign you in. Please try again.',
      };
    }
    return 'Sign-in error: $error';
  }
}

class AuthSetupException implements Exception {
  const AuthSetupException(this.message);
  final String message;
}
