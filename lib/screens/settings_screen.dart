import 'package:flutter/material.dart';

import '../models/focus_input.dart';
import '../services/settings_service.dart';
import '../theme/focusflow_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/appearance_settings_card.dart';
import '../widgets/app_info_card.dart';
import '../widgets/cloud_data_management_card.dart';
import '../widgets/cloud_sync_card.dart';
import '../widgets/export_data_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/local_data_management_card.dart';
import '../widgets/mvp_release_checklist_card.dart';
import '../widgets/privacy_summary_card.dart';
import '../widgets/profile_settings_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.pagePadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 130),
          children: [
            const _SettingsHeader(),

            const SizedBox(height: 20),

            const ProfileSettingsCard(),

            const SizedBox(height: 12),

            const AppearanceSettingsCard(),

            const SizedBox(height: 20),

            const _SectionHeader(icon: Icons.devices_outlined, label: 'Device'),
            const SizedBox(height: 10),
            const _PlatformSelector(),

            const SizedBox(height: 20),

            const _SectionHeader(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
            ),
            const SizedBox(height: 10),
            const _NotificationSettingsGroup(),

            const SizedBox(height: 20),

            const _SectionHeader(
              icon: Icons.cloud_sync_outlined,
              label: 'Data & Sync',
            ),
            const SizedBox(height: 10),

            const CloudSyncCard(),
            const SizedBox(height: 12),

            const PrivacySummaryCard(),
            const SizedBox(height: 12),

            const ExportDataCard(),
            const SizedBox(height: 12),

            const LocalDataManagementCard(),
            const SizedBox(height: 12),

            const CloudDataManagementCard(),
            const SizedBox(height: 20),

            const _SectionHeader(
              icon: Icons.verified_outlined,
              label: 'Release',
            ),
            const SizedBox(height: 10),

            const MvpReleaseChecklistCard(),
            const SizedBox(height: 12),

            const AppInfoCard(),
            const SizedBox(height: 20),

            const _SectionHeader(icon: Icons.info_outline, label: 'About'),
            const SizedBox(height: 10),

            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About FocusFlow',
              subtitle: 'A privacy-first focus and digital wellness platform.',
              accentColor: FocusFlowTheme.secondary,
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('FocusFlow'),
          content: const Text(
            'FocusFlow helps you understand your focus, screen-time balance, '
            'recovery rhythm, and productivity patterns.\n\n'
            'Detailed activity stays local. Cloud sync uses summary-only data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Control profile, sync, privacy, exports, and FocusFlow release settings.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FocusFlowTheme.primary,
                FocusFlowTheme.secondary.withValues(alpha: 0.72),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: FocusFlowTheme.primary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.settings_outlined, color: Colors.white),
        ),
      ],
    );
  }
}

class _NotificationSettingsGroup extends StatelessWidget {
  const _NotificationSettingsGroup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: SettingsService.notificationsEnabled,
          builder: (context, value, _) {
            return _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Allow FocusFlow alerts and gentle reminders.',
              accentColor: FocusFlowTheme.primary,
              trailing: Switch(
                value: value,
                onChanged: SettingsService.setNotifications,
              ),
              onTap: () => SettingsService.setNotifications(!value),
            );
          },
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: SettingsService.breakRemindersEnabled,
          builder: (context, value, _) {
            return _SettingsTile(
              icon: Icons.timer_outlined,
              title: 'Break Reminders',
              subtitle: 'Enable 20-20-20 eye-health break reminders.',
              accentColor: FocusFlowTheme.warning,
              trailing: Switch(
                value: value,
                onChanged: SettingsService.setBreakReminders,
              ),
              onTap: () => SettingsService.setBreakReminders(!value),
            );
          },
        ),
      ],
    );
  }
}

class _PlatformSelector extends StatelessWidget {
  const _PlatformSelector();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DevicePlatform>(
      valueListenable: SettingsService.platform,
      builder: (context, currentPlatform, _) {
        final selectedPlatform = currentPlatform == DevicePlatform.android
            ? DevicePlatform.android
            : DevicePlatform.windows;

        return GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _platformColor(
                        selectedPlatform,
                      ).withValues(alpha: 0.16),
                    ),
                    child: Icon(
                      _platformIcon(selectedPlatform),
                      color: _platformColor(selectedPlatform),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Device',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calibrates scoring thresholds for your current device.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: SegmentedButton<DevicePlatform>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<DevicePlatform>(
                      value: DevicePlatform.windows,
                      icon: Icon(Icons.desktop_windows_outlined, size: 18),
                      label: Text('Windows'),
                    ),
                    ButtonSegment<DevicePlatform>(
                      value: DevicePlatform.android,
                      icon: Icon(Icons.phone_android_outlined, size: 18),
                      label: Text('Android'),
                    ),
                  ],
                  selected: {selectedPlatform},
                  onSelectionChanged: (selection) {
                    SettingsService.setPlatform(selection.first);
                  },
                ),
              ),

              const SizedBox(height: 14),

              _ThresholdHint(platform: selectedPlatform),
            ],
          ),
        );
      },
    );
  }

  static IconData _platformIcon(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.android:
        return Icons.phone_android_outlined;
      case DevicePlatform.windows:
        return Icons.desktop_windows_outlined;
      case DevicePlatform.tablet:
        return Icons.tablet_outlined;
      case DevicePlatform.web:
        return Icons.language_outlined;
    }
  }

  static Color _platformColor(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.android:
        return FocusFlowTheme.success;
      case DevicePlatform.windows:
        return FocusFlowTheme.secondary;
      case DevicePlatform.tablet:
        return FocusFlowTheme.warning;
      case DevicePlatform.web:
        return FocusFlowTheme.primary;
    }
  }
}

class _ThresholdHint extends StatelessWidget {
  final DevicePlatform platform;

  const _ThresholdHint({required this.platform});

  @override
  Widget build(BuildContext context) {
    final isWindows = platform == DevicePlatform.windows;

    final items = isWindows
        ? const [
            _ThresholdItem('Deep work target', '90 min'),
            _ThresholdItem('Healthy screen time', '≤ 6 h'),
            _ThresholdItem('Switch tolerance', '≤ 40 / day'),
          ]
        : const [
            _ThresholdItem('Deep work target', '45 min'),
            _ThresholdItem('Healthy screen time', '≤ 3 h'),
            _ThresholdItem('Switch tolerance', '≤ 60 / day'),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWindows
                  ? 'Windows scoring thresholds'
                  : 'Android scoring thresholds',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: FocusFlowTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            for (final item in items) ...[
              _ThresholdRow(label: item.label, value: item.value),
              if (item != items.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String label;
  final String value;

  const _ThresholdRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ThresholdItem {
  final String label;
  final String value;

  const _ThresholdItem(this.label, this.value);
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FocusFlowTheme.secondary),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accentColor.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
