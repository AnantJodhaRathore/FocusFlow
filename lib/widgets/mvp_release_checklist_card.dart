import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MvpReleaseChecklistCard extends StatefulWidget {
  const MvpReleaseChecklistCard({super.key});

  @override
  State<MvpReleaseChecklistCard> createState() =>
      _MvpReleaseChecklistCardState();
}

class _MvpReleaseChecklistCardState extends State<MvpReleaseChecklistCard> {
  static const String _storageKey = 'focusflow_mvp_release_checklist';

  static const List<_ChecklistItem> _items = [
    _ChecklistItem(
      id: 'local_tracking',
      title: 'Local tracking works',
      description: 'Activity monitoring records local usage correctly.',
    ),
    _ChecklistItem(
      id: 'dashboard',
      title: 'Dashboard loads',
      description: 'Focus score, screen time, and recovery data display.',
    ),
    _ChecklistItem(
      id: 'analytics',
      title: 'Analytics works',
      description: 'Charts and trends load without crashing.',
    ),
    _ChecklistItem(
      id: 'eye_health',
      title: 'Eye Health works',
      description: 'Break/recovery guidance appears correctly.',
    ),
    _ChecklistItem(
      id: 'cloud_sync',
      title: 'Cloud summary sync works',
      description: 'Daily summary sync succeeds in Firebase.',
    ),
    _ChecklistItem(
      id: 'privacy_guard',
      title: 'Privacy guard active',
      description:
          'Raw activity logs, app names, and window titles are not synced.',
    ),
    _ChecklistItem(
      id: 'export',
      title: 'Export summary data works',
      description: 'JSON export creates summary-only files.',
    ),
    _ChecklistItem(
      id: 'delete_local',
      title: 'Delete local data works',
      description: 'Local data deletion works after confirmation.',
    ),
    _ChecklistItem(
      id: 'release_build',
      title: 'Release build works',
      description: 'focusflow.exe launches from Release folder.',
    ),
    _ChecklistItem(
      id: 'readme',
      title: 'README updated',
      description: 'README includes Firebase sync, privacy, and limitations.',
    ),
  ];

  Set<String> _checkedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? [];

    if (!mounted) return;

    setState(() {
      _checkedIds = saved.toSet();
      _loading = false;
    });
  }

  Future<void> _setChecked(String id, bool value) async {
    final updated = Set<String>.from(_checkedIds);

    if (value) {
      updated.add(id);
    } else {
      updated.remove(id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated.toList()..sort());

    if (!mounted) return;

    setState(() {
      _checkedIds = updated;
    });
  }

  Future<void> _resetChecklist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset MVP checklist?'),
          content: const Text(
            'This will uncheck all MVP release checklist items.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    if (!mounted) return;

    setState(() {
      _checkedIds = {};
    });
  }

  double get _progress {
    if (_items.isEmpty) return 0;
    return _checkedIds.length / _items.length;
  }

  bool get _isComplete => _checkedIds.length == _items.length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: _loading
          ? const LinearProgressIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isComplete
                          ? Icons.verified_outlined
                          : Icons.checklist_outlined,
                      color: _isComplete
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'MVP Release Checklist',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text('${_checkedIds.length}/${_items.length}'),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 12),
                Text(
                  _isComplete
                      ? 'FocusFlow MVP RC1 is ready for packaging.'
                      : 'Complete these checks before packaging FocusFlow MVP RC1.',
                ),
                const SizedBox(height: 8),
                ..._items.map((item) {
                  final checked = _checkedIds.contains(item.id);

                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: checked,
                    onChanged: (value) {
                      _setChecked(item.id, value ?? false);
                    },
                    title: Text(item.title),
                    subtitle: Text(item.description),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _resetChecklist,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset checklist'),
                ),
              ],
            ),
    );
  }
}

class _ChecklistItem {
  final String id;
  final String title;
  final String description;

  const _ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
  });
}
