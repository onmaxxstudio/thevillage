import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

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

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
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
    return credential;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  bool _googleInitialized = false;

  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) return _auth.signInWithPopup(provider);

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
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() {
    final provider = AppleAuthProvider();
    return kIsWeb
        ? _auth.signInWithPopup(provider)
        : _auth.signInWithProvider(provider);
  }

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
        'account-exists-with-different-credential' =>
          'That email already uses a different sign-in method.',
        _ => error.message ?? 'We could not sign you in. Please try again.',
      };
    }
    return 'We could not sign you in. Please try again.';
  }
}

class AuthSetupException implements Exception {
  const AuthSetupException(this.message);
  final String message;
}
