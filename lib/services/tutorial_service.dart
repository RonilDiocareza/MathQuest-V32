import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TutorialService {
  static FirebaseAuth? get _authOrNull {
    try {
      return FirebaseAuth.instance;
    } on FirebaseException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static CollectionReference<Map<String, dynamic>> get _users {
    try {
      return FirebaseFirestore.instance.collection('users');
    } on FirebaseException {
      throw StateError('Firebase Firestore is not available because Firebase is not initialized.');
    } catch (_) {
      throw StateError('Firebase Firestore is not available because Firebase is not initialized.');
    }
  }

  static Future<bool> shouldShowFirstTimeTutorial(String uid) async {
    final user = _authOrNull?.currentUser;
    debugPrint(
      '[TutorialService] Checking tutorial state: '
      'authCurrentUser=${user != null}, authUid=${user?.uid ?? '(none)'}, '
      'requestedUid=$uid, document=users/$uid, '
      'fields=tutorialEligible,tutorialCompleted.',
    );
    if (user == null || user.uid != uid) {
      throw StateError(
        'The authenticated user does not match the tutorial account.',
      );
    }

    try {
      final snapshot = await _users.doc(uid).get();
      debugPrint(
        '[TutorialService] Tutorial state read completed: '
        'document=users/$uid, exists=${snapshot.exists}.',
      );
      final data = snapshot.data();
      final eligible = data?['tutorialEligible'];
      final completed = data?['tutorialCompleted'];
      debugPrint(
        '[TutorialService] Tutorial state values: '
        'tutorialEligible=$eligible '
        '(${eligible?.runtimeType ?? 'null'}), '
        'tutorialCompleted=$completed '
        '(${completed?.runtimeType ?? 'null'}).',
      );
      return snapshot.exists &&
          eligible == true &&
          completed != true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[TutorialService] Tutorial state read failed: '
        'plugin=${error.plugin}, code=${error.code}, '
        'message=${error.message ?? '(none)'}.',
      );
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        '[TutorialService] Tutorial state check failed: '
        'type=${error.runtimeType}, message=$error.',
      );
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> completeFirstTimeTutorial() async {
    final user = _authOrNull?.currentUser;
    if (user == null) {
      throw StateError('Sign in before saving tutorial progress.');
    }
    if (user.uid.isEmpty) {
      throw StateError('The signed-in account has no user ID.');
    }

    final documentPath = 'users/${user.uid}';
    debugPrint(
      '[TutorialService] Starting Firestore update: '
      'authCurrentUser=true, authUid=${user.uid}, document=$documentPath, '
      'field=tutorialCompleted, value=true, '
      'authenticatedUidMatchesDocumentId=true.',
    );
    try {
      await _users.doc(user.uid).update({'tutorialCompleted': true});
      debugPrint(
        '[TutorialService] Firestore update succeeded: '
        'document=$documentPath, field=tutorialCompleted, value=true.',
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[TutorialService] Firestore update failed: '
        'authCurrentUser=${_authOrNull?.currentUser != null}, '
        'authUid=${_authOrNull?.currentUser?.uid ?? '(none)'}, '
        'document=$documentPath, field=tutorialCompleted, value=true, '
        'plugin=${error.plugin}, code=${error.code}, '
        'message=${error.message ?? '(none)'}.',
      );
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        '[TutorialService] Firestore update failed: '
        'authCurrentUser=${_authOrNull?.currentUser != null}, '
        'authUid=${_authOrNull?.currentUser?.uid ?? '(none)'}, '
        'document=$documentPath, field=tutorialCompleted, value=true, '
        'type=${error.runtimeType}, message=$error.',
      );
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
