import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String title;
  final String type;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String? thumbnailUrl;
  final String? aiSummary;
  final List<String> tags;
  final DateTime? uploadedAt;

  const ReportModel({
    required this.id,
    required this.title,
    required this.type,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.thumbnailUrl,
    this.aiSummary,
    this.tags = const [],
    this.uploadedAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      title: d['title'] ?? '',
      type: d['type'] ?? 'other',
      filePath: d['file_path'] ?? '',
      fileName: d['file_name'] ?? '',
      fileSize: d['file_size'] ?? 0,
      fileType: d['file_type'] ?? 'pdf',
      thumbnailUrl: d['thumbnail_url'],
      aiSummary: d['ai_summary'],
      tags: List<String>.from(d['tags'] ?? []),
      uploadedAt: (d['uploaded_at'] as Timestamp?)?.toDate(),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'lab_report':
        return 'Lab Report';
      case 'prescription':
        return 'Prescription';
      case 'scan':
        return 'Scan';
      default:
        return 'Document';
    }
  }

  String get fileSizeLabel {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
