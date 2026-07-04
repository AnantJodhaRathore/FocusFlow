import 'package:flutter/material.dart';

import '../services/first_launch_service.dart';
import '../theme/focusflow_theme.dart';
import '../widgets/animated_app_background.dart';
import '../widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _pageIndex = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.psychology_alt_outlined,
      title: 'Welcome to FocusFlow',
      subtitle:
          'Track your focus, understand your work patterns, and build healthier screen habits.',
      color: FocusFlowTheme.primary,
    ),
    _OnboardingPageData(
      icon: Icons.lock_outline,
      title: 'Privacy-first tracking',
      subtitle:
          'FocusFlow stores detailed activity locally. Cloud sync uses daily summaries only.',
      color: FocusFlowTheme.secondary,
    ),
    _OnboardingPageData(
      icon: Icons.analytics_outlined,
      title: 'Understand your focus',
      subtitle:
          'See focus score, productive time, screen-time balance, recovery, and deep work trends.',
      color: FocusFlowTheme.success,
    ),
    _OnboardingPageData(
      icon: Icons.visibility_outlined,
      title: 'Protect your eyes',
      subtitle:
          'Track breaks and screen-time rhythm so long work sessions stay healthier.',
      color: FocusFlowTheme.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_pageIndex < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await FirstLaunchService.instance.completeOnboarding();
  }

  Future<void> _skip() async {
    await FirstLaunchService.instance.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _pageIndex == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedAppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _OnboardingPage(
                          key: ValueKey(page.title),
                          data: page,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _OnboardingDots(
                  count: _pages.length,
                  selectedIndex: _pageIndex,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      isLastPage
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward,
                    ),
                    label: Text(isLastPage ? 'Start FocusFlow' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        data.color.withValues(alpha: 0.95),
                        data.color.withValues(alpha: 0.42),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withValues(alpha: 0.30),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Icon(data.icon, size: 42, color: Colors.white),
                ),
                const SizedBox(height: 28),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const _OnboardingDots({required this.count, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == selectedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: selected ? 28 : 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? FocusFlowTheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.22),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
