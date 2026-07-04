import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter.blur

import 'activity_screen.dart' as activity;
import 'analytics_screen.dart' as analytics;
import 'dashboard_screen.dart' as dashboard;
import 'eye_health_screen.dart' as eye;
import 'settings_screen.dart' as settings;
import '../widgets/animated_app_background.dart';
import '../widgets/animated_tab_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = <Widget>[
    const dashboard.DashboardScreen(),
    const analytics.AnalyticsScreen(),
    const eye.EyeHealthScreen(),
    const activity.ActivityScreen(),
    const settings.SettingsScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody:
          true, // Allows the background to shine through behind the nav bar
      body: AnimatedAppBackground(
        child: SafeArea(
          bottom:
              false, // Prevents aggressive clipping since extendBody is true
          child: AnimatedTabBody(
            selectedIndex: _selectedIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        // Overriding the default navigation bar theme for a sleek, transparent look
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  color: theme.colorScheme.primary,
                  size: 26,
                );
              }
              return IconThemeData(
                color: theme.unselectedWidgetColor,
                size: 24,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final baseStyle = const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              );
              if (states.contains(WidgetState.selected)) {
                return baseStyle.copyWith(color: theme.colorScheme.primary);
              }
              return baseStyle.copyWith(color: theme.unselectedWidgetColor);
            }),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ), // Updated padding to 16 from Step 3
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              28,
            ), // Updated corner radius to 28 from Step 3
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ), // Frosted glass effect
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(
                    28,
                  ), // Matched container radius to 28
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  height: 70,
                  elevation: 0,
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: 'Analytics',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.visibility_outlined),
                      selectedIcon: Icon(Icons.visibility),
                      label: 'Eye Health',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.timeline_outlined),
                      selectedIcon: Icon(Icons.timeline),
                      label: 'Activity',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
