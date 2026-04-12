import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message_model.dart';

class CuraRepository {
  final _firestore = FirebaseFirestore.instance;

  static const String _functionUrl =
      'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/curaChat';

  static bool get _isConfigured => !_functionUrl.contains('YOUR_REGION');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _chatsRef =>
      _firestore.collection('users').doc(_uid).collection('chats');

  Stream<List<ChatMessageModel>> watchChats() {
    return _chatsRef
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage(String text, {String? relatedReportId}) async {
    await _chatsRef.add({
      'role': 'user',
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'is_escalation': false,
      'related_report_id': relatedReportId,
    });

    if (!_isConfigured) {
      await _chatsRef.add({
        'role': 'cura',
        'message':
            "Hi! I'm Cura, your AI health assistant.\n\n"
            "I'm not connected to my AI brain yet. That still needs a Gemini API key and a deployed Cloud Function.\n\n"
            "Once that setup is done, I'll be able to answer health questions, analyze reports, and give personalized advice.\n\n"
            "For now, feel free to explore the rest of the app.",
        'timestamp': FieldValue.serverTimestamp(),
        'is_escalation': false,
      });
      return;
    }

    try {
      final token = await FirebaseAuth.instance.currentUser!.getIdToken();

      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'uid': _uid,
              'message': text,
              if (relatedReportId != null) 'reportId': relatedReportId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      String reply;
      bool isDanger = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['response'] as String? ??
            "I received your message but couldn't generate a response. Please try again.";
        isDanger = data['isDanger'] as bool? ?? false;
      } else {
        reply =
            "I'm having trouble connecting right now (error ${response.statusCode}). Please try again in a moment.";
      }

      await _chatsRef.add({
        'role': 'cura',
        'message': reply,
        'timestamp': FieldValue.serverTimestamp(),
        'is_escalation': isDanger,
        'related_report_id': relatedReportId,
      });
    } catch (_) {
      await _chatsRef.add({
        'role': 'cura',
        'message':
            "I couldn't reach the server. Please check your internet connection and try again.",
        'timestamp': FieldValue.serverTimestamp(),
        'is_escalation': false,
      });
    }
  }

  Future<void> clearChats() async {
    final batch = _firestore.batch();
    final snapshot = await _chatsRef.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
