import 'package:flutter/material.dart';
import 'glass_card.dart';

class PrivacySummaryCard extends StatelessWidget {
  const PrivacySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware adaptive tokens for structural elements
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
              Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Privacy',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'FocusFlow is local-first. Your activity data is stored safely on this device.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 14),

          // Wrapped the privacy details in a structured adaptive container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: subtleFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              children: [
                _PrivacyRow(
                  icon: Icons.check_circle_outline,
                  iconColor: colorScheme.primary,
                  text: 'Cloud Sync uploads daily summary metrics only.',
                ),
                const _PrivacyRow(
                  icon: Icons.block_outlined,
                  text: 'Raw activity logs are not uploaded.',
                ),
                const _PrivacyRow(
                  icon: Icons.block_outlined,
                  text: 'App names are not uploaded in cloud summary sync.',
                ),
                const _PrivacyRow(
                  icon: Icons.block_outlined,
                  text:
                      'Window titles, URLs, file names, and typed text are never uploaded.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Current sync path: users/{uid}/daily_summaries/{date}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;

  const _PrivacyRow({required this.icon, this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
