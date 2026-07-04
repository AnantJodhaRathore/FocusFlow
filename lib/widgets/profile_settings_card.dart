import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/auth_screen.dart';
import '../services/auth_service.dart';
import '../theme/focusflow_theme.dart';
import 'glass_card.dart';

class ProfileSettingsCard extends StatefulWidget {
  const ProfileSettingsCard({super.key});

  @override
  State<ProfileSettingsCard> createState() => _ProfileSettingsCardState();
}

class _ProfileSettingsCardState extends State<ProfileSettingsCard> {
  bool _loading = false;

  Future<void> _openAuthScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  Future<void> _logout() async {
    setState(() {
      _loading = true;
    });

    try {
      await AuthService.instance.signOutToGuestMode();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out. FocusFlow is now in guest mode.'),
        ),
      );
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isAccountUser = user != null && !user.isAnonymous;

        return GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isAccountUser
                        ? FocusFlowTheme.primary.withValues(alpha: 0.20)
                        : FocusFlowTheme.warning.withValues(alpha: 0.18),
                    backgroundImage: isAccountUser && user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: isAccountUser && user.photoURL != null
                        ? null
                        : Icon(
                            isAccountUser
                                ? Icons.person_outline
                                : Icons.person_off_outlined,
                            color: isAccountUser
                                ? FocusFlowTheme.primary
                                : FocusFlowTheme.warning,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAccountUser
                              ? (user.displayName?.isNotEmpty == true
                                    ? user.displayName!
                                    : 'FocusFlow User')
                              : 'Guest Mode',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAccountUser
                              ? user.email ?? 'Signed in'
                              : 'Create an account to use profile login and cloud identity.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        isAccountUser
                            ? Icons.cloud_done_outlined
                            : Icons.lock_outline,
                        color: isAccountUser
                            ? FocusFlowTheme.success
                            : FocusFlowTheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAccountUser
                              ? 'Cloud sync is linked to this account.'
                              : 'Local data stays on this device. Cloud sync can still use guest mode.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (isAccountUser)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _logout,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _openAuthScreen,
                        icon: const Icon(Icons.login),
                        label: const Text('Login / Create Profile'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
