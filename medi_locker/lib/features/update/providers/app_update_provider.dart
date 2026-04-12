import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_update_repository.dart';

final appUpdateRepositoryProvider =
    Provider<AppUpdateRepository>((_) => AppUpdateRepository());

final appVersionProvider = FutureProvider<String>((ref) async {
  return ref.watch(appUpdateRepositoryProvider).getCurrentVersion();
});
