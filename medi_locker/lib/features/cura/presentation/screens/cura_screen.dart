import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';

class ChatMessage {
  final String id;
  final String role;
  final String message;
  final bool isEscalation;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.message,
    this.isEscalation = false,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      role: d['role'] ?? 'user',
      message: d['message'] ?? '',
      isEscalation: d['is_escalation'] ?? false,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CuraScreen extends StatefulWidget {
  const CuraScreen({super.key});

  @override
  State<CuraScreen> createState() => _CuraScreenState();
}

class _CuraScreenState extends State<CuraScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;

  static const _functionUrl =
      'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/curaChat';

  static const _suggestions = [
    'What does my blood pressure reading mean?',
    'Suggest a diet for high cholesterol',
    'I have a headache, what should I do?',
    'How often should I get a blood test?',
  ];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _chatsRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('chats');

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty || _isTyping) return;
    _msgCtrl.clear();

    await _chatsRef.add({
      'role': 'user',
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'is_escalation': false,
    });

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final token = await FirebaseAuth.instance.currentUser!.getIdToken();
      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'uid': _uid, 'message': text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _chatsRef.add({
          'role': 'cura',
          'message': data['response'] as String? ??
              'I could not understand the response from the server.',
          'timestamp': FieldValue.serverTimestamp(),
          'is_escalation': data['isDanger'] as bool? ?? false,
        });
      } else {
        await _chatsRef.add({
          'role': 'cura',
          'message': 'I am having trouble connecting right now. Please try again in a moment.',
          'timestamp': FieldValue.serverTimestamp(),
          'is_escalation': false,
        });
      }
    } catch (_) {
      await _chatsRef.add({
        'role': 'cura',
        'message': _functionUrl.contains('YOUR_REGION')
            ? 'Cura AI is not set up yet. Update the Cloud Function URL in cura_screen.dart when your backend is ready.'
            : 'I am unable to connect right now. Please check your internet and try again.',
        'timestamp': FieldValue.serverTimestamp(),
        'is_escalation': false,
      });
    }

    if (mounted) setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await _chatsRef.get();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cura', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  'AI Health Assistant',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear chat',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Delete all messages with Cura?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirm == true) await _clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFDE7),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cura is not a substitute for professional medical advice.',
                    style: TextStyle(fontSize: 11, color: AppColors.warning.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatsRef.orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final messages = snap.data?.docs.map((d) => ChatMessage.fromFirestore(d)).toList() ?? [];
                if (messages.isEmpty) {
                  return _WelcomeState(
                    suggestions: _suggestions,
                    onSuggestionTap: _sendMessage,
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isTyping && i == messages.length) {
                      return const _TypingIndicator();
                    }
                    return _ChatBubble(msg: messages[i]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask Cura anything about your health...',
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.textHintDark : AppColors.textHintLight),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : msg.isEscalation
                        ? AppColors.escalationContainer
                        : (isDark ? AppColors.cardDark : AppColors.cardLight),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: !isUser
                    ? Border.all(
                        color: msg.isEscalation
                            ? AppColors.escalation.withValues(alpha: 0.4)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.isEscalation) ...[
                    const Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.error, size: 14),
                        SizedBox(width: 4),
                        Text('Emergency Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser
                          ? Colors.white
                          : msg.isEscalation
                              ? AppColors.error
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: FadeTransition(
              opacity: _anim,
              child: const Row(
                children: [
                  _Dot(),
                  SizedBox(width: 4),
                  _Dot(),
                  SizedBox(width: 4),
                  _Dot(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
    );
  }
}

class _WelcomeState extends StatelessWidget {
  final List<String> suggestions;
  final Future<void> Function(String) onSuggestionTap;

  const _WelcomeState({required this.suggestions, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.smart_toy, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Hi! I am Cura', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Your AI health assistant. I can help you understand your reports, answer health questions, and give general wellness advice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.6, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(height: 10),
          ...suggestions.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              child: GestureDetector(
                onTap: () => onSuggestionTap(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondaryLight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
