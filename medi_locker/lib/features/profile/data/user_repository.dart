import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/user_model.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference get _userDoc => _firestore.collection('users').doc(_uid);

  /// Real-time stream of the current user's profile.
  Stream<UserModel?> watchCurrentUser() {
    return _userDoc.snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  Future<UserModel?> getCurrentUser() async {
    final snap = await _userDoc.get();
    if (!snap.exists) return null;
    return UserModel.fromFirestore(snap);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? bloodGroup,
    String? gender,
    DateTime? dob,
    List<String>? allergies,
    List<String>? chronicConditions,
  }) async {
    final updates = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'name': '$firstName $lastName',
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (phone != null) updates['phone'] = phone;
    if (bloodGroup != null) updates['blood_group'] = bloodGroup;
    if (gender != null) updates['gender'] = gender;
    if (dob != null) updates['dob'] = Timestamp.fromDate(dob);
    if (allergies != null) updates['allergies'] = allergies;
    if (chronicConditions != null) updates['chronic_conditions'] = chronicConditions;

    await _userDoc.update(updates);
  }

  Future<void> saveFcmToken(String token) async {
    await _userDoc.update({'fcm_token': token});
  }

  Future<String> exportAccountData() async {
    final user = await getCurrentUser();
    final chats = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .orderBy('timestamp', descending: false)
        .get();
    final reports = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('reports')
        .orderBy('uploaded_at', descending: true)
        .get();

    final payload = {
      'exported_at': DateTime.now().toIso8601String(),
      'uid': _uid,
      'profile': _jsonSafe(user?.toMap()),
      'reports': reports.docs
          .map((doc) => _jsonSafe({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList(),
      'chats': chats.docs
          .map((doc) => _jsonSafe({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList(),
    };

    final downloadsDir = Directory('/storage/emulated/0/Download');
    final fallbackDir = await getApplicationDocumentsDirectory();
    final baseDir = await _ensureDirectory(downloadsDir) ?? fallbackDir;
    final file = File('${baseDir.path}/medi_locker_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Future<void> deleteAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final lastSignInTime = currentUser?.metadata.lastSignInTime;
    final requiresRecentLogin = lastSignInTime == null ||
        DateTime.now().difference(lastSignInTime) > const Duration(minutes: 10);
    if (requiresRecentLogin) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Recent sign-in required before deleting account.',
      );
    }

    final reportsSnap = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('reports')
        .get();
    for (final doc in reportsSnap.docs) {
      final filePath = (doc.data()['file_path'] ?? '').toString();
      if (filePath.isNotEmpty) {
        try {
          await _storage.ref(filePath).delete();
        } catch (_) {}
      }
    }

    await _deleteCollection(_firestore.collection('users').doc(_uid).collection('reports'));
    await _deleteCollection(_firestore.collection('users').doc(_uid).collection('chats'));
    await _userDoc.delete();
    await currentUser?.delete();
  }

  dynamic _jsonSafe(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _jsonSafe(val)));
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList();
    }
    return value;
  }

  Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<Directory?> _ensureDirectory(Directory directory) async {
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (_) {
      return null;
    }
  }
}
