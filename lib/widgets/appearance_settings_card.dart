import 'package:flutter/material.dart';

import '../services/theme_mode_service.dart';
import '../theme/focusflow_theme.dart';
import 'glass_card.dart';

class AppearanceSettingsCard extends StatelessWidget {
  const AppearanceSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeModeService.instance.themeMode,
        builder: (context, themeMode, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.palette_outlined,
                    color: FocusFlowTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Appearance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Choose how FocusFlow looks across Windows and Android.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SegmentedButton<ThemeMode>(
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  ThemeModeService.instance.setThemeMode(selection.first);
                },
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.devices_outlined),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
