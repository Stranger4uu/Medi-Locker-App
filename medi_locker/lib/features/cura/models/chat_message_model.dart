import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String role; // 'user' | 'cura'
  final String message;
  final bool isEscalation;
  final String? relatedReportId;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.message,
    this.isEscalation = false,
    this.relatedReportId,
    required this.timestamp,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      role: d['role'] ?? 'user',
      message: d['message'] ?? '',
      isEscalation: d['is_escalation'] ?? false,
      relatedReportId: d['related_report_id'],
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isCura => role == 'cura';
}
