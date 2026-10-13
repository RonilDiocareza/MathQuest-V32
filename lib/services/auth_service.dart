import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_account.dart';
import 'leaderboard_service.dart';

class AuthService {
  static FirebaseAuth get _auth {
    try {
      return FirebaseAuth.instance;
    } on FirebaseException {
      throw StateError('Firebase Auth is not available because Firebase is not initialized.');
    } catch (_) {
      throw StateError('Firebase Auth is not available because Firebase is not initialized.');
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

  static CollectionReference<Map<String, dynamic>> get _sessions {
    try {
      return FirebaseFirestore.instance.collection('activeSessions');
    } on FirebaseException {
      throw StateError('Firebase Firestore is not available because Firebase is not initialized.');
    } catch (_) {
      throw StateError('Firebase Firestore is not available because Firebase is not initialized.');
    }
  }

  static const _deviceIdKey = 'mathquest_device_id';
  static const _sessionIdKeyPrefix = 'mathquest_session_id_';

  static User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } on FirebaseException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<UserAccount> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final uid = credential.user!.uid;
    String? sessionId;
    String? deviceId;
    try {
      deviceId = await _getDeviceId();
      sessionId = await _claimLoginSession(uid, deviceId);

      final account = await getAccount(uid);
      if (account == null) {
        throw StateError(
          'Your account profile is missing for UID $uid. '
          'Create the users document with this exact ID in the same Firebase project.',
        );
      }
      if (!account.isApproved) {
        throw StateError('Account pending admin approval.');
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        '$_sessionIdKeyPrefix$uid',
        sessionId,
      );
      return account;
    } catch (_) {
      var failedSessionId = sessionId;
      failedSessionId ??= sessionId;
      if (failedSessionId != null && deviceId != null) {
        try {
          await _releaseLoginSession(uid, deviceId, failedSessionId);
        } catch (error, stackTrace) {
          debugPrint('Unable to release failed login session: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      await _auth.signOut();
      rethrow;
    }
  }

  static Future<UserAccount> register({
    required String email,
    required String password,
    required String name,
    required String address,
    required String lrn,
    required String character,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final authUser = credential.user!;
    final account = UserAccount(
      uid: authUser.uid,
      email: normalizedEmail,
      role: 'student',
      status: 'pending',
      name: name,
      address: address,
      lrn: lrn,
      character: character,
    );
    try {
      final batch = FirebaseFirestore.instance.batch();
      final userData = account.toJson()
        ..['tutorialEligible'] = true
        ..['tutorialCompleted'] = false;
      batch.set(_users.doc(authUser.uid), userData);
      batch.set(FirebaseFirestore.instance.collection('lrnIndexes').doc(lrn), {
        'uid': authUser.uid,
        'lrn': lrn,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      try {
        await LeaderboardService.createRegistrationEntry(
          uid: authUser.uid,
          displayName: name,
        );
      } catch (error, stackTrace) {
        debugPrint(
            'Unable to initialize pending student leaderboard entry: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } catch (error) {
      try {
        await authUser.delete();
      } catch (cleanupError, stackTrace) {
        debugPrint('Unable to clean up rejected registration: $cleanupError');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    } finally {
      try {
        await _auth.signOut();
      } catch (error, stackTrace) {
        debugPrint('Unable to sign out after registration: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return account;
  }

  static Future<UserAccount?> getAccount(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return UserAccount.fromJson({...snapshot.data()!, 'uid': snapshot.id});
  }

  static Future<List<UserAccount>> loadAccounts() async {
    final snapshot = await _users.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserAccount.fromJson({...doc.data(), 'uid': doc.id}))
        .toList();
  }

  static Future<void> updateAccount(UserAccount account) {
    final currentLrn = account.lrn.trim();
    return _users.doc(account.uid).get().then((snapshot) {
      if (snapshot.data()?['lrn'] != currentLrn) {
        throw StateError('An account LRN cannot be changed.');
      }
      final data = account.toJson()..remove('uid');
      return _users.doc(account.uid).update(data);
    });
  }

  static Future<void> deleteAccount(UserAccount account) async {
    final lrnIndex =
        FirebaseFirestore.instance.collection('lrnIndexes').doc(account.lrn);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final indexSnapshot = await transaction.get(lrnIndex);
      transaction.delete(_users.doc(account.uid));
      if (indexSnapshot.data()?['uid'] == account.uid) {
        transaction.delete(lrnIndex);
      }
    });
  }

  static Future<void> updateCurrentProfile({
    required String name,
    required String address,
    String? profilePhotoUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in.');
    final updates = <String, dynamic>{
      'name': name,
      'address': address,
    };
    if (profilePhotoUrl != null) {
      updates['profilePhotoUrl'] = profilePhotoUrl;
    }
    await _users.doc(user.uid).update(updates);
  }

  static Future<void> updateCurrentProfilePhotoUrl(String photoUrl) async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in.');
    await _users.doc(user.uid).update({'profilePhotoUrl': photoUrl});
  }

  static Future<String> _getDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_deviceIdKey);
    if (existing != null && existing.length >= 16) return existing;

    final random = Random.secure();
    final deviceId = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await preferences.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  static Future<String> _claimLoginSession(String uid, String deviceId) {
    final sessionRef = _sessions.doc(uid);
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        if (data['deviceId'] != deviceId) {
          throw StateError(
            'This account is already active on another device. '
            'Sign out there first, or ask an admin to clear its session.',
          );
        }
        final existingSessionId = data['sessionId'];
        if (existingSessionId is! String || existingSessionId.isEmpty) {
          throw StateError(
            'This device session is incomplete. Ask an administrator to clear it.',
          );
        }
        return existingSessionId;
      }

      final sessionId = _generateSessionId();
      transaction.set(sessionRef, {
        'deviceId': deviceId,
        'sessionId': sessionId,
        'claimedAt': FieldValue.serverTimestamp(),
      });
      return sessionId;
    });
  }

  static String _generateSessionId() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Future<void> _releaseLoginSession(
    String uid,
    String deviceId,
    String sessionId,
  ) async {
    final sessionRef = _sessions.doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      if (data['deviceId'] == deviceId && data['sessionId'] == sessionId) {
        transaction.delete(sessionRef);
      }
    });
  }

  static Future<void> signOut() async {
    final currentUid = _auth.currentUser?.uid;
    final uid = currentUid;
    final preferences = await SharedPreferences.getInstance();
    String? sessionId =
        uid == null ? null : preferences.getString('$_sessionIdKeyPrefix$uid');
    if (uid != null && _auth.currentUser != null) {
      final deviceId = await _getDeviceId();
      if (sessionId == null) {
        final snapshot = await _sessions.doc(uid).get();
        final data = snapshot.data();
        if (data?['deviceId'] == deviceId && data?['sessionId'] is String) {
          sessionId = data!['sessionId'] as String;
        }
      }
      if (sessionId != null) {
        await _releaseLoginSession(uid, deviceId, sessionId);
      }
    }
    if (uid != null) await preferences.remove('$_sessionIdKeyPrefix$uid');
    await _auth.signOut();
  }

  static Future<void> clearAccountLoginSession(String uid) async {
    await _sessions.doc(uid).delete();
  }
}
