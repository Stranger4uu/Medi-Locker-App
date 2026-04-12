import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/encryption_util.dart';
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
        .map((snap) =>
            snap.docs.map((doc) => ReportModel.fromFirestore(doc)).toList());
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

    File uploadFile = file;
    bool encrypted = false;
    File? tempEncFile;

    try {
      final tempDir = await getTemporaryDirectory();
      tempEncFile = File('${tempDir.path}/$reportId.enc');
      await EncryptionUtil.encryptFile(file, tempEncFile);
      uploadFile = tempEncFile;
      encrypted = true;
    } catch (_) {
      encrypted = false;
      uploadFile = file;
    }

    final storagePath = encrypted
        ? 'users/$_uid/reports/$reportId.enc'
        : 'users/$_uid/reports/$reportId.$ext';

    try {
      final ref = _storage.ref(storagePath);
      final uploadTask = ref.putFile(
        uploadFile,
        SettableMetadata(
          contentType: encrypted
              ? 'application/octet-stream'
              : (isImage ? 'image/$ext' : 'application/pdf'),
          customMetadata: {
            'uid': _uid,
            'report_id': reportId,
            'original_ext': ext,
            'encrypted': encrypted.toString(),
          },
        ),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });

      await uploadTask;
    } finally {
      if (tempEncFile != null && await tempEncFile.exists()) {
        await tempEncFile.delete();
      }
    }

    final fileSize = await file.length();

    await _reportsRef.doc(reportId).set({
      'title': title,
      'type': type,
      'file_path': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': isImage ? 'image' : 'pdf',
      'original_ext': ext,
      'is_encrypted': encrypted,
      'thumbnail_url': null,
      'ai_summary': null,
      'tags': <String>[],
      'uploaded_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    final doc = await _reportsRef.doc(reportId).get();
    return ReportModel.fromFirestore(doc);
  }

  Future<String> getDecryptedFilePath(ReportModel report) async {
    final tempDir = await getTemporaryDirectory();
    final ext = report.originalExt ?? 'pdf';

    if (!report.isEncrypted) {
      final localFile = File('${tempDir.path}/${report.id}.$ext');
      await _storage.ref(report.filePath).writeToFile(localFile);
      return localFile.path;
    }

    final encFile = File('${tempDir.path}/${report.id}.enc');
    final decFile = File('${tempDir.path}/${report.id}.$ext');

    await _storage.ref(report.filePath).writeToFile(encFile);
    await EncryptionUtil.decryptFile(encFile, decFile);

    if (await encFile.exists()) {
      await encFile.delete();
    }

    return decFile.path;
  }

  Future<String> saveReportForUser(ReportModel report) async {
    final sourcePath = await getDecryptedFilePath(report);
    final sourceFile = File(sourcePath);
    final downloadsDir = Directory('/storage/emulated/0/Download/Medi Locker');
    final fallbackDir = await getApplicationDocumentsDirectory();
    final baseDir = await _ensureDirectory(downloadsDir) ?? fallbackDir;

    final safeName = report.fileName.trim().isEmpty
        ? '${report.title}.${report.originalExt ?? 'pdf'}'
        : report.fileName;
    final targetFile =
        File('${baseDir.path}/${_buildUniqueName(baseDir, safeName)}');

    await sourceFile.copy(targetFile.path);
    return targetFile.path;
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

  String _buildUniqueName(Directory dir, String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';
    final candidate = File('${dir.path}/$fileName');
    if (!candidate.existsSync()) {
      return fileName;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_$timestamp$extension';
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
