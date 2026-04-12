import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/report_model.dart';

class RecordsRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _reportsRef =>
      _firestore.collection('users').doc(_uid).collection('reports');

  Stream<List<ReportModel>> watchReports() {
    return _reportsRef
        .orderBy('uploaded_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReportModel.fromFirestore(d)).toList());
  }

  Future<ReportModel?> getReport(String reportId) async {
    final doc = await _reportsRef.doc(reportId).get();
    if (!doc.exists) return null;
    return ReportModel.fromFirestore(doc);
  }

  Future<ReportModel> uploadReport({
    required File file,
    required String title,
    required String type,
    required String fileName,
    void Function(double)? onProgress,
  }) async {
    final reportId = _uuid.v4();
    final ext = fileName.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
    final storagePath = 'users/$_uid/reports/$reportId.$ext';

    final ref = _storage.ref(storagePath);
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: isImage ? 'image/$ext' : 'application/pdf',
        customMetadata: {'uid': _uid, 'report_id': reportId},
      ),
    );

    uploadTask.snapshotEvents.listen((snap) {
      final total = snap.totalBytes == 0 ? 1 : snap.totalBytes;
      onProgress?.call(snap.bytesTransferred / total);
    });

    await uploadTask;
    final fileSize = await file.length();

    await _reportsRef.doc(reportId).set({
      'title': title,
      'type': type,
      'file_path': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': isImage ? 'image' : 'pdf',
      'thumbnail_url': null,
      'ai_summary': null,
      'tags': [],
      'uploaded_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    final doc = await _reportsRef.doc(reportId).get();
    return ReportModel.fromFirestore(doc);
  }

  Future<String> getDownloadUrl(String storagePath) async {
    return _storage.ref(storagePath).getDownloadURL();
  }

  Future<void> deleteReport(String reportId, String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
    await _reportsRef.doc(reportId).delete();
  }
}
