import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/cura_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/cura_typing_indicator.dart';

class CuraScreen extends ConsumerStatefulWidget {
  const CuraScreen({super.key});

  @override
  ConsumerState<CuraScreen> createState() => _CuraScreenState();
}

class _CuraScreenState extends ConsumerState<CuraScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    if (ref.read(curaTypingProvider)) return;

    _msgCtrl.clear();
    ref.read(curaTypingProvider.notifier).state = true;
    _scrollToBottom();

    try {
      await ref.read(curaRepositoryProvider).sendMessage(text);
    } finally {
      if (mounted) {
        ref.read(curaTypingProvider.notifier).state = false;
        _scrollToBottom();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(chatMessagesProvider);
    final isTyping = ref.watch(curaTypingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cura',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text('AI Health Assistant',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondaryLight)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear chat',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: isDark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFFFFDE7),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 13, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cura is not a substitute for professional medical advice.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty && !isTyping) {
                  return _WelcomeState(
                    onSuggestion: (s) {
                      _msgCtrl.text = s;
                      _send();
                    },
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (isTyping && i == messages.length) {
                      return const CuraTypingIndicator();
                    }
                    return ChatBubble(message: messages[i]);
                  },
                );
              },
            ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12,
                MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask Cura anything...',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isTyping
                          ? AppColors.textSecondaryLight
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Delete all messages with Cura?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(curaRepositoryProvider).clearChats();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome / empty state ───────────────────────────────────────────────────
class _WelcomeState extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _WelcomeState({required this.onSuggestion});

  static const _suggestions = [
    'What does my blood pressure reading mean?',
    'Suggest a diet for high cholesterol',
    'I have a headache — what should I do?',
    'How often should I get a blood test?',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.smart_toy,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text("Hi! I'm Cura",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Your AI health assistant. Ask me about your reports, symptoms, diet, or general wellness.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Try asking:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)),
          ),
          const SizedBox(height: 10),
          ..._suggestions.map((s) => GestureDetector(
                onTap: () => onSuggestion(s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s,
                          style: const TextStyle(fontSize: 13))),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.textSecondaryLight),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
