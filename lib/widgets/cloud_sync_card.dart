import 'package:flutter/material.dart';
import 'glass_card.dart';

import '../services/firebase_sync_queue_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/settings_service.dart';

class CloudSyncCard extends StatefulWidget {
  const CloudSyncCard({super.key});

  @override
  State<CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends State<CloudSyncCard> {
  bool _syncing = false;
  bool _loadingPendingCount = true;

  int _pendingCount = 0;

  FirebaseSyncStatus _status = FirebaseSyncService.instance.status;
  DateTime? _lastSyncedAt = FirebaseSyncService.instance.lastSyncedAt;
  String? _lastError = FirebaseSyncService.instance.lastError;
  String? _lastDocumentPath;

  @override
  void initState() {
    super.initState();
    SettingsService.syncEnabled.addListener(_handleSettingsChanged);
    _loadPendingCount();
  }

  @override
  void dispose() {
    SettingsService.syncEnabled.removeListener(_handleSettingsChanged);
    super.dispose();
  }

  void _handleSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPendingCount() async {
    final count = await FirebaseSyncQueueService.instance.pendingCount();

    if (!mounted) return;

    setState(() {
      _pendingCount = count;
      _loadingPendingCount = false;
    });
  }

  Future<void> _syncToday() async {
    if (_syncing) return;

    if (!SettingsService.syncEnabled.value) {
      _showSnackBar('Turn on Cloud Sync first.');
      return;
    }

    setState(() {
      _syncing = true;
      _status = FirebaseSyncStatus.syncing;
      _lastError = null;
    });

    final retryCount = await FirebaseSyncService.instance
        .retryPendingDailySummaries();

    final result = await FirebaseSyncService.instance.syncTodaySummary();

    debugPrint(
      '[FocusFlow] Manual sync retried pending summaries: $retryCount',
    );

    await _loadPendingCount();

    if (!mounted) return;

    setState(() {
      _syncing = false;
      _status = result.status;
      _lastSyncedAt = FirebaseSyncService.instance.lastSyncedAt;
      _lastError = FirebaseSyncService.instance.lastError;
      _lastDocumentPath = result.documentPath;
    });

    if (result.isSuccess) {
      _showSnackBar('Today’s summary synced.');
    } else {
      _showSnackBar('Sync failed. It will retry later.');
    }
  }

  Future<void> _retryPending() async {
    if (_syncing) return;

    if (!SettingsService.syncEnabled.value) {
      _showSnackBar('Turn on Cloud Sync first.');
      return;
    }

    setState(() {
      _syncing = true;
      _status = FirebaseSyncStatus.syncing;
      _lastError = null;
    });

    final retryCount = await FirebaseSyncService.instance
        .retryPendingDailySummaries();

    await _loadPendingCount();

    if (!mounted) return;

    setState(() {
      _syncing = false;
      _status = FirebaseSyncService.instance.status;
      _lastSyncedAt = FirebaseSyncService.instance.lastSyncedAt;
      _lastError = FirebaseSyncService.instance.lastError;
    });

    _showSnackBar('Retried $retryCount pending summaries.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel() {
    if (_syncing) return 'Syncing';

    switch (_status) {
      case FirebaseSyncStatus.idle:
        return 'Idle';
      case FirebaseSyncStatus.syncing:
        return 'Syncing';
      case FirebaseSyncStatus.success:
        return 'Success';
      case FirebaseSyncStatus.error:
        return 'Error';
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Never';

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '$day-$month-$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final syncEnabled = SettingsService.syncEnabled.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware adaptive tokens for inline structural elements
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Cloud Sync', style: textTheme.titleMedium),
            subtitle: Text(
              'Sync daily focus summaries only. Raw activity logs are not uploaded.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: syncEnabled,
            onChanged: SettingsService.setSync,
          ),
          const SizedBox(height: 12),

          // Wrapped the status display inside an adaptive layout container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: subtleFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subtleBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: syncEnabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Status: ${_statusLabel()}\n'
                    'Last synced: ${_formatDateTime(_lastSyncedAt)}\n'
                    'Pending summaries: ${_loadingPendingCount ? 'Loading...' : _pendingCount}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh pending count',
                  onPressed: syncEnabled ? _loadPendingCount : null,
                  icon: Icon(
                    Icons.refresh,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_lastDocumentPath != null) ...[
            const SizedBox(height: 8),
            Text(
              'Path: $_lastDocumentPath',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (_lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: $_lastError',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: syncEnabled && !_syncing ? _syncToday : null,
                  icon: _syncing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(_syncing ? 'Syncing...' : 'Sync today'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: syncEnabled && !_syncing && _pendingCount > 0
                      ? _retryPending
                      : null,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Retry pending'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Privacy: only summary metrics are synced. App names, window titles, and raw activity rows stay local.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
