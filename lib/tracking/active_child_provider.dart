import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActiveChildProvider {
  static Future<String?> getActiveChildId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .get();

    return doc.data()?['activeChildId'] as String?;
  }
}
