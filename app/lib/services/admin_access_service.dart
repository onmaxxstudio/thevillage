import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminAccessService {
  bool get cloudReady => Firebase.apps.isNotEmpty;

  Future<bool> isCurrentUserAdmin() async {
    if (!cloudReady) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      return snapshot.exists && snapshot.data()?['active'] == true;
    } on FirebaseException {
      return false;
    }
  }
}