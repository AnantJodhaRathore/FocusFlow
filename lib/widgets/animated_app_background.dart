import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedAppBackground extends StatefulWidget {
  final Widget child;

  const AnimatedAppBackground({super.key, required this.child});

  @override
  State<AnimatedAppBackground> createState() => _AnimatedAppBackgroundState();
}

class _AnimatedAppBackgroundState extends State<AnimatedAppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use standard dynamic theme tokens instead of static file properties
    final backgroundColor = colorScheme.surface;

    final primaryAlpha = isDark ? 0.22 : 0.12;
    final secondaryAlpha = isDark ? 0.18 : 0.10;

    // Fallback to primary / secondary configurations if specific domain hues are unmapped
    final successColor = isDark ? Colors.tealAccent : Colors.teal;
    final successAlpha = isDark ? 0.08 : 0.06;

    return ColoredBox(
      color: backgroundColor,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final value = _controller.value;
          final wave = math.sin(value * math.pi * 2);

          return Stack(
            children: [
              // ── Background Ambient Radial Glow ─────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.7 + wave * 0.12, -0.9),
                      radius: 1.25,
                      colors: [
                        colorScheme.primary.withValues(alpha: primaryAlpha),
                        backgroundColor,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Top Right Blob (Secondary Accent) ──────────────────────────
              Positioned(
                top: -90 + wave * 20,
                right: -80,
                child: _GlowBlob(
                  size: 260,
                  color: colorScheme.secondary.withValues(
                    alpha: secondaryAlpha,
                  ),
                ),
              ),

              // ── Bottom Left Blob (Primary Accent) ──────────────────────────
              Positioned(
                bottom: -120,
                left: -90 + wave * 24,
                child: _GlowBlob(
                  size: 300,
                  color: colorScheme.primary.withValues(alpha: primaryAlpha),
                ),
              ),

              // ── Mid Left Accent Blob ───────────────────────────────────────
              Positioned(
                top: 260 + wave * 16,
                left: 40,
                child: _GlowBlob(
                  size: 160,
                  color: successColor.withValues(alpha: successAlpha),
                ),
              ),

              Positioned.fill(child: child!),
            ],
          );
        },
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.55,
              spreadRadius: size * 0.12,
            ),
          ],
        ),
      ),
    );
  }
}
