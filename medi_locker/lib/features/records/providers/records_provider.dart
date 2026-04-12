import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/records_repository.dart';
import '../models/report_model.dart';

final recordsRepositoryProvider =
    Provider<RecordsRepository>((_) => RecordsRepository());

/// Real-time stream of all reports for the current user.
final reportsStreamProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(recordsRepositoryProvider).watchReports();
});

/// Total count of uploaded reports.
final reportCountProvider = Provider<int>((ref) {
  return ref.watch(reportsStreamProvider).value?.length ?? 0;
});
