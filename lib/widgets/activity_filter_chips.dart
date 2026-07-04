import 'package:flutter/material.dart';

import '../theme/focusflow_theme.dart';

class ActivityFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const ActivityFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  static const List<String> filters = [
    'All',
    'Productive',
    'Distracting',
    'Neutral',
    'Break',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = selectedFilter == filter;

        return ChoiceChip(
          label: Text(filter),
          selected: selected,
          onSelected: (_) => onChanged(filter),
          selectedColor: FocusFlowTheme.primary.withValues(alpha: 0.28),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          side: BorderSide(
            color: selected
                ? FocusFlowTheme.primary.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.10),
          ),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}
