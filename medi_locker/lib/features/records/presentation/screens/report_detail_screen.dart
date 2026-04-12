import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/records_repository.dart';
import '../../models/report_model.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  ReportModel? _report;
  bool _loading = true;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = RecordsRepository();
      final report = await repo.getReport(widget.reportId);
      if (report == null) {
        if (mounted) context.pop();
        return;
      }
      String? url;
      try {
        url = await repo.getDownloadUrl(report.filePath);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _report = report;
          _downloadUrl = url;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Delete "${_report!.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await RecordsRepository().deleteReport(_report!.id, _report!.filePath);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Report not found')),
      );
    }

    final r = _report!;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: r.fileType == 'image' && _downloadUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _downloadUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _FileIcon(type: r.type),
                      ),
                    )
                  : _FileIcon(type: r.type),
            ),
            const SizedBox(height: 20),
            _InfoCard(
              children: [
                _Row(label: 'Title', value: r.title),
                _Row(label: 'Type', value: r.typeLabel),
                _Row(label: 'File', value: r.fileName),
                _Row(label: 'Size', value: r.fileSizeLabel),
                if (r.uploadedAt != null)
                  _Row(label: 'Uploaded', value: '${r.uploadedAt!.day}/${r.uploadedAt!.month}/${r.uploadedAt!.year}'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Cura AI Summary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.aiSummary?.isNotEmpty == true
                          ? r.aiSummary!
                          : 'No AI summary yet. This will be generated when you ask Cura to analyze this report.',
                      style: TextStyle(
                        fontSize: 13,
                        color: r.aiSummary?.isNotEmpty == true
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/cura'),
                icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
                label: const Text('Ask Cura about this report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  final String type;
  const _FileIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'prescription' ? Icons.medication_outlined : Icons.picture_as_pdf,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const Text('Document', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
