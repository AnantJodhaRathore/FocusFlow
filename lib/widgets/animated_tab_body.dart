import 'package:flutter/material.dart';

class AnimatedTabBody extends StatelessWidget {
  final int selectedIndex;
  final List<Widget> children;

  const AnimatedTabBody({
    super.key,
    required this.selectedIndex,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(selectedIndex),
        child: children[selectedIndex],
      ),
    );
  }
}
