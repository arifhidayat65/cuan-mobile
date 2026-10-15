import 'package:flutter/material.dart';

/// Subtle entrance animation (Magic UI: fade-in on page load).
/// Wraps list items / sections with staggered delay support.
class FadeIn extends StatelessWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = 12.0,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    // Respect reduced motion.
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final t = ((value * (duration.inMilliseconds + delay.inMilliseconds) -
                    delay.inMilliseconds) /
                duration.inMilliseconds)
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
