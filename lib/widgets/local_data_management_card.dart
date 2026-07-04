import 'package:flutter/material.dart';
import 'glass_card.dart';

import '../services/firebase_sync_queue_service.dart';
import '../services/storage_service.dart';

class LocalDataManagementCard extends StatefulWidget {
  const LocalDataManagementCard({super.key});

  @override
  State<LocalDataManagementCard> createState() =>
      _LocalDataManagementCardState();
}

class _LocalDataManagementCardState extends State<LocalDataManagementCard> {
  bool _loading = true;
  bool _deleting = false;

  int _activityCount = 0;
  int _sessionCount = 0;
  int _attentionFlowCount = 0;
  int _recoveryMetricCount = 0;
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      await StorageService.instance.initialize();

      final activities = await StorageService.instance.getActivities();
      final sessions = await StorageService.instance.getSessions();
      final attentionFlows = await StorageService.instance.getAttentionFlows();
      final recoveryMetrics = await StorageService.instance
          .getRecoveryMetrics();
      final pendingSyncCount = await FirebaseSyncQueueService.instance
          .pendingCount();

      if (!mounted) return;

      setState(() {
        _activityCount = activities.length;
        _sessionCount = sessions.length;
        _attentionFlowCount = attentionFlows.length;
        _recoveryMetricCount = recoveryMetrics.length;
        _pendingSyncCount = pendingSyncCount;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSnackBar('Could not load local data counts.');
    }
  }

  Future<void> _deleteLocalData() async {
    if (_deleting) return;

    final confirmed = await _showDeleteConfirmationDialog();

    if (confirmed != true) return;

    setState(() {
      _deleting = true;
    });

    try {
      await StorageService.instance.initialize();
      await StorageService.instance.clearAllData();

      // This queue stores dates only, but clearing it prevents retrying summaries
      // after the local source data has been deleted.
      await FirebaseSyncQueueService.instance.clear();

      if (!mounted) return;

      setState(() {
        _activityCount = 0;
        _sessionCount = 0;
        _attentionFlowCount = 0;
        _recoveryMetricCount = 0;
        _pendingSyncCount = 0;
        _deleting = false;
      });

      _showSnackBar('Local FocusFlow data deleted.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      _showSnackBar('Delete failed. Check debug console.');
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete local data?'),
          content: const Text(
            'This will permanently delete local FocusFlow activity data, '
            'focus sessions, attention flows, recovery metrics, and pending '
            'sync retry dates from this device.\n\n'
            'Cloud daily summaries in Firebase will not be deleted.',
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
              child: const Text('Delete local data'),
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

  int get _totalLocalItems {
    return _activityCount +
        _sessionCount +
        _attentionFlowCount +
        _recoveryMetricCount;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Local Data',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh counts',
                onPressed: _loading || _deleting ? null : _loadCounts,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Manage data stored on this device. This does not delete cloud daily summaries.',
          ),
          const SizedBox(height: 12),
          if (_loading)
            const LinearProgressIndicator()
          else ...[
            _CountRow(label: 'Activity records', value: _activityCount),
            _CountRow(label: 'Focus sessions', value: _sessionCount),
            _CountRow(label: 'Attention flows', value: _attentionFlowCount),
            _CountRow(label: 'Recovery metrics', value: _recoveryMetricCount),
            _CountRow(label: 'Pending sync dates', value: _pendingSyncCount),
            const SizedBox(height: 8),
            Text(
              'Total local records: $_totalLocalItems',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _loading || _deleting ? null : _deleteLocalData,
            icon: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(_deleting ? 'Deleting...' : 'Delete local data'),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int value;

  const _CountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
