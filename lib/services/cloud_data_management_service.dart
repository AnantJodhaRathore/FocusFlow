import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CloudDeleteResult {
  final bool success;
  final int deletedCount;
  final String? message;

  const CloudDeleteResult({
    required this.success,
    required this.deletedCount,
    this.message,
  });
}

class CloudDataManagementService {
  CloudDataManagementService._internal();

  static final CloudDataManagementService instance =
      CloudDataManagementService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getDailySummaryCount() async {
    final user = await _ensureSignedIn();

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('daily_summaries')
        .get();

    return snapshot.docs.length;
  }

  Future<CloudDeleteResult> deleteDailySummaries() async {
    try {
      final user = await _ensureSignedIn();

      final collectionRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries');

      var deletedCount = 0;

      while (true) {
        final snapshot = await collectionRef.limit(400).get();

        if (snapshot.docs.isEmpty) {
          break;
        }

        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        deletedCount += snapshot.docs.length;
      }

      debugPrint(
        '[FocusFlow] Deleted $deletedCount cloud daily summary documents.',
      );

      return CloudDeleteResult(
        success: true,
        deletedCount: deletedCount,
        message: 'Cloud daily summaries deleted.',
      );
    } catch (error, stackTrace) {
      debugPrint('[FocusFlow] Cloud summary delete error: $error');
      debugPrint('$stackTrace');

      return CloudDeleteResult(
        success: false,
        deletedCount: 0,
        message: error.toString(),
      );
    }
  }

  Future<User> _ensureSignedIn() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) return currentUser;

    final credential = await _auth.signInAnonymously();
    final user = credential.user;

    if (user == null) {
      throw StateError('Anonymous Firebase sign-in returned null user.');
    }

    return user;
  }
}
