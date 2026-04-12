import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

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

  Future<void> deleteAccount() async {
    await _userDoc.delete();
    await FirebaseAuth.instance.currentUser?.delete();
  }
}
