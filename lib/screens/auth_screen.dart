import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/focusflow_theme.dart';
import '../widgets/animated_app_background.dart';
import '../widgets/glass_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _createAccount = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_createAccount) {
        await AuthService.instance.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      } else {
        await AuthService.instance.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter your email first, then tap Forgot password.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await AuthService.instance.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _successMessage = 'Password reset email sent.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await AuthService.instance.signInWithGoogle();

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
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
    final title = _createAccount ? 'Create Profile' : 'Sign In';
    final subtitle = _createAccount
        ? 'Create a FocusFlow account for cloud sync and profile access.'
        : 'Sign in to your FocusFlow account.';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedAppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  colors: [
                                    FocusFlowTheme.primary,
                                    FocusFlowTheme.secondary.withValues(
                                      alpha: 0.75,
                                    ),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- Google Sign-In Button Block ---
                        FilledButton.icon(
                          onPressed: _loading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Continue with Google'),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'or',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.16),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ------------------------------------
                        if (_createAccount) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) {
                              if (!_createAccount) return null;

                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your display name.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your email.';
                            }

                            if (!value.contains('@')) {
                              return 'Enter a valid email.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password.';
                            }

                            if (_createAccount && value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        if (!_createAccount)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: FocusFlowTheme.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],

                        if (_successMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: FocusFlowTheme.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _createAccount
                                      ? Icons.person_add_alt_1_outlined
                                      : Icons.login,
                                ),
                          label: Text(
                            _createAccount ? 'Create Account' : 'Sign In',
                          ),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _createAccount = !_createAccount;
                                    _errorMessage = null;
                                    _successMessage = null;
                                  });
                                },
                          child: Text(
                            _createAccount
                                ? 'Already have an account? Sign in'
                                : 'New here? Create profile',
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Continue without account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
