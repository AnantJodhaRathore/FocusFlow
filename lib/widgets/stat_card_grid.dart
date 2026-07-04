import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';

class StatCardGrid extends StatelessWidget {
  final List<Widget> children;

  const StatCardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.gridColumns(context);
    final spacing = ResponsiveUtils.isCompact(context) ? 12.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}
