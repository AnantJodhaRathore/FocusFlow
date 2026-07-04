import 'package:flutter/material.dart';
import 'glass_card.dart';

import '../services/cloud_data_management_service.dart';
import '../services/settings_service.dart';

class CloudDataManagementCard extends StatefulWidget {
  const CloudDataManagementCard({super.key});

  @override
  State<CloudDataManagementCard> createState() =>
      _CloudDataManagementCardState();
}

class _CloudDataManagementCardState extends State<CloudDataManagementCard> {
  bool _loading = true;
  bool _deleting = false;

  int _cloudSummaryCount = 0;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    SettingsService.syncEnabled.addListener(_handleSettingsChanged);
    _loadCount();
  }

  @override
  void dispose() {
    SettingsService.syncEnabled.removeListener(_handleSettingsChanged);
    super.dispose();
  }

  void _handleSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCount() async {
    if (!SettingsService.syncEnabled.value) {
      if (!mounted) return;

      setState(() {
        _cloudSummaryCount = 0;
        _loading = false;
        _lastError = null;
      });

      return;
    }

    setState(() {
      _loading = true;
      _lastError = null;
    });

    try {
      final count = await CloudDataManagementService.instance
          .getDailySummaryCount();

      if (!mounted) return;

      setState(() {
        _cloudSummaryCount = count;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _lastError = error.toString();
      });
    }
  }

  Future<void> _deleteCloudSummaries() async {
    if (_deleting) return;

    if (!SettingsService.syncEnabled.value) {
      _showSnackBar('Turn on Cloud Sync first.');
      return;
    }

    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _lastError = null;
    });

    final result = await CloudDataManagementService.instance
        .deleteDailySummaries();

    if (!mounted) return;

    setState(() {
      _deleting = false;
      _cloudSummaryCount = result.success ? 0 : _cloudSummaryCount;
      _lastError = result.success ? null : result.message;
    });

    _showSnackBar(
      result.success
          ? 'Deleted ${result.deletedCount} cloud summaries.'
          : 'Cloud delete failed. Check console.',
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete cloud summaries?'),
          content: const Text(
            'This will permanently delete your synced daily summary documents '
            'from Firebase.\n\n'
            'This does not delete local FocusFlow data on this device and does '
            'not delete your Firebase account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete cloud summaries'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final syncEnabled = SettingsService.syncEnabled.value;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Cloud Data',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh cloud summary count',
                onPressed: syncEnabled && !_loading && !_deleting
                    ? _loadCount
                    : null,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Manage summary documents synced to Firebase. Raw activity logs are not stored in cloud sync.',
          ),
          const SizedBox(height: 12),
          if (!syncEnabled)
            const Text('Cloud Sync is off.')
          else if (_loading)
            const LinearProgressIndicator()
          else
            Text(
              'Cloud daily summaries: $_cloudSummaryCount',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          if (_lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: $_lastError',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: syncEnabled && !_loading && !_deleting
                ? _deleteCloudSummaries
                : null,
            icon: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(_deleting ? 'Deleting...' : 'Delete cloud summaries'),
          ),
        ],
      ),
    );
  }
}
