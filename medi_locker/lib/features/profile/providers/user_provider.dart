import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_repository.dart';
import '../models/user_model.dart';

final userRepositoryProvider =
    Provider<UserRepository>((_) => UserRepository());

/// Real-time stream of the current user's profile document.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(userRepositoryProvider).watchCurrentUser();
});

/// Convenience: first name of the logged-in user.
final userFirstNameProvider = Provider<String>((ref) {
  return ref.watch(currentUserProfileProvider).value?.firstName ?? 'there';
});
