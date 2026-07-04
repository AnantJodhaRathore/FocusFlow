import 'package:flutter/material.dart';

import 'glass_card.dart';

class LoadingSkeletonCard extends StatefulWidget {
  final double height;
  final int lines;

  const LoadingSkeletonCard({super.key, this.height = 150, this.lines = 4});

  @override
  State<LoadingSkeletonCard> createState() => _LoadingSkeletonCardState();
}

class _LoadingSkeletonCardState extends State<LoadingSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final value = _controller.value;

                return LinearGradient(
                  begin: Alignment(-1.5 + value * 3, -0.4),
                  end: Alignment(-0.4 + value * 3, 0.4),
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ).createShader(bounds);
              },
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 72, height: 72, borderRadius: 24),
              const SizedBox(height: 18),
              ...List.generate(widget.lines, (index) {
                final widthFactor = switch (index) {
                  0 => 0.72,
                  1 => 0.92,
                  2 => 0.55,
                  _ => 0.78,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FractionallySizedBox(
                    widthFactor: widthFactor,
                    child: const _SkeletonBox(height: 14, borderRadius: 999),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
