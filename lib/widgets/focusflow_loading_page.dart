import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';
import 'loading_skeleton_card.dart';

class FocusFlowLoadingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final int cards;

  const FocusFlowLoadingPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.cards = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.pagePadding(context),
        ResponsiveUtils.pagePadding(context),
        ResponsiveUtils.pagePadding(context),
        110,
      ),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        ...List.generate(
          cards,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: LoadingSkeletonCard(
              height: index == 0 ? 190 : 140,
              lines: index == 0 ? 4 : 3,
            ),
          ),
        ),
      ],
    );
  }
}
