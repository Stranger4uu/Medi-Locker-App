import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_runtime_config.dart';
import 'runtime_config_repository.dart';

final runtimeConfigRepositoryProvider =
    Provider<RuntimeConfigRepository>((_) => RuntimeConfigRepository());

final runtimeConfigProvider = FutureProvider<AppRuntimeConfig>((ref) async {
  return ref.watch(runtimeConfigRepositoryProvider).initialize();
});
