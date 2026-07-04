import 'package:flutter/material.dart';
import 'glass_card.dart';

class AppInfoCard extends StatelessWidget {
  const AppInfoCard({super.key});

  static const String appName = 'FocusFlow';
  static const String appVersion = '0.1.0';
  static const String buildNumber = '1';
  static const String releaseStage = 'Windows MVP';
  static const String privacyModel = 'Local-first, summary-only cloud sync';

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
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'About FocusFlow',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _InfoRow(label: 'App', value: appName),
          const _InfoRow(label: 'Version', value: '$appVersion+$buildNumber'),
          const _InfoRow(label: 'Stage', value: releaseStage),
          const _InfoRow(label: 'Privacy', value: privacyModel),
          const SizedBox(height: 12),
          Text(
            'FocusFlow helps track focus, recovery, screen time, and productivity patterns on this device.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
