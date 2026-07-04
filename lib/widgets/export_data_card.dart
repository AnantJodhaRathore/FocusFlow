import 'package:flutter/material.dart';
import 'glass_card.dart';

import '../services/daily_summary_export_service.dart';

class ExportDataCard extends StatefulWidget {
  const ExportDataCard({super.key});

  @override
  State<ExportDataCard> createState() => _ExportDataCardState();
}

class _ExportDataCardState extends State<ExportDataCard> {
  bool _exporting = false;
  String? _lastExportPath;
  String? _lastError;

  Future<void> _exportLast7Days() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
      _lastError = null;
    });

    final result = await DailySummaryExportService.instance.exportLast7Days();

    if (!mounted) return;

    setState(() {
      _exporting = false;
      _lastExportPath = result.filePath;
      _lastError = result.success ? null : result.message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Daily summaries exported.'
              : 'Export failed. Check console.',
        ),
      ),
    );
  }

  Future<void> _exportToday() async {
    if (_exporting) return;

    setState(() {
      _exporting = true;
      _lastError = null;
    });

    final result = await DailySummaryExportService.instance.exportToday();

    if (!mounted) return;

    setState(() {
      _exporting = false;
      _lastExportPath = result.filePath;
      _lastError = result.success ? null : result.message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Today’s summary exported.'
              : 'Export failed. Check console.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware adaptive tokens for context boxes
    final subtleFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.035);

    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_download_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Export Local Data',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Export daily summary metrics as JSON. Raw activity logs, app names, and window titles are not exported.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _exporting ? null : _exportToday,
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('Export today'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportLast7Days,
                  icon: _exporting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.calendar_view_week_outlined),
                  label: Text(_exporting ? 'Exporting...' : 'Export 7 days'),
                ),
              ),
            ],
          ),
          if (_lastExportPath != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: subtleFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: subtleBorder),
              ),
              child: Text(
                'Saved to: $_lastExportPath',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          if (_lastError != null) ...[
            const SizedBox(height: 12),
            Text(
              'Error: $_lastError',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
