import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/date_util.dart';
import '../../data/records_repository.dart';
import '../../models/report_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportModel? _report;
  File? _decryptedFile;
  bool _loading = true;
  bool _decrypting = false;
  bool _downloading = false;

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
      setState(() {
        _report = report;
        _loading = false;
      });
      if (report.fileType == 'image') {
        _loadDecryptedFile();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadDecryptedFile() async {
    if (_report == null) return;
    setState(() => _decrypting = true);
    try {
      final path = await RecordsRepository().getDecryptedFilePath(_report!);
      if (mounted) {
        setState(() => _decryptedFile = File(path));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _decrypting = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Delete "${_report!.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await RecordsRepository().deleteReport(_report!.id, _report!.filePath);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    }
  }

  Future<void> _downloadReport() async {
    if (_report == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final path = await RecordsRepository().saveReportForUser(_report!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to: $path'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Report not found')),
      );
    }

    final report = _report!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          report.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: _buildPreview(report),
            ),
            const SizedBox(height: 20),
            _InfoCard(
              children: [
                _Row(label: 'Title', value: report.title),
                _Row(label: 'Type', value: report.typeLabel),
                _Row(label: 'File', value: report.fileName),
                _Row(label: 'Size', value: report.fileSizeLabel),
                _Row(
                  label: 'Encrypted',
                  value: report.isEncrypted ? 'Yes (AES-256)' : 'No',
                ),
                if (report.uploadedAt != null)
                  _Row(
                    label: 'Uploaded',
                    value: DateUtil.formatDisplay(report.uploadedAt!),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Cura AI Summary',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report.aiSummary?.isNotEmpty == true
                          ? report.aiSummary!
                          : 'No AI summary yet. Ask Cura to analyze this report.',
                      style: TextStyle(
                        fontSize: 13,
                        color: report.aiSummary?.isNotEmpty == true
                            ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight)
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
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
              child: OutlinedButton.icon(
                onPressed: _downloading ? null : _downloadReport,
                icon: _downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(
                  _downloading ? 'Saving...' : 'Download Report',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/cura'),
                icon: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                ),
                label: const Text('Ask Cura about this report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ReportModel report) {
    if (_decrypting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Decrypting file...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (report.fileType == 'image' && _decryptedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _decryptedFile!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _FileIcon(type: report.type),
        ),
      );
    }

    if (report.fileType == 'image' && _decryptedFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loadDecryptedFile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Load Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _FileIcon(type: report.type);
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
            type == 'prescription'
                ? Icons.medication_outlined
                : Icons.picture_as_pdf,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF Document',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
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
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
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
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
