import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Billing state is server-owned. Never grant Plus access from a checkout redirect.
class VillagePlusBilling {
  static String? get uid => FirebaseAuth.instance.currentUser?.uid;

  static Stream<bool> get active {
    final userId = uid;
    if (userId == null) return Stream<bool>.value(false);
    return FirebaseFirestore.instance
        .collection('villagePlusEntitlements').doc(userId)
        .snapshots().map((snapshot) => snapshot.data()?['active'] == true);
  }

  static Future<void> join() async => _openSession('createVillagePlusCheckout');

  static Future<void> manage() async => _openSession('createVillagePlusPortal');

  static Future<void> _openSession(String function) async {
    if (uid == null) throw StateError('Sign in to manage Village Plus.');
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable(function).call(<String, dynamic>{});
    final url = result.data is Map ? result.data['url'] as String? : null;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' ||
        (uri.host != 'checkout.stripe.com' && uri.host != 'billing.stripe.com')) {
      throw StateError('Secure billing page unavailable. Please try again.');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Could not open the secure billing page.');
    }
  }
}
