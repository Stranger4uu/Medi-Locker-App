import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cura_repository.dart';
import '../models/chat_message_model.dart';

final curaRepositoryProvider =
    Provider<CuraRepository>((_) => CuraRepository());

/// Real-time stream of all Cura chat messages.
final chatMessagesProvider = StreamProvider<List<ChatMessageModel>>((ref) {
  return ref.watch(curaRepositoryProvider).watchChats();
});

/// Loading state for when Cura is generating a response.
final curaTypingProvider = StateProvider<bool>((_) => false);
