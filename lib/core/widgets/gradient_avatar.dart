import 'package:flutter/material.dart';

import '../theme/ledger_theme.dart';

/// Icon tile used across lists.
/// Prefers solid surfaces (anti-slop); gradient only for brand moments
/// (lock screen, onboarding) via [gradient].
/// Foreground color is auto-derived from luminance, so icons stay readable.
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    required this.icon,
    this.gradient,
    this.color,
    this.iconColor,
    this.size = 44,
    this.iconSize = 22,
    this.radius = 12,
  }) : assert(gradient != null || color != null,
            'Provide either gradient or color');

  final IconData icon;
  final Gradient? gradient;
  final Color? color;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double radius;

  /// Solid tile — the default for list icons (data-first, no rainbow).
  const GradientAvatar.solid({
    super.key,
    required this.icon,
    this.iconColor,
    this.size = 44,
    this.iconSize = 22,
    this.radius = 12,
  })  : gradient = null,
        color = null;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? LedgerTheme.surface2;
    final fg = iconColor ??
        (gradient != null
            ? LedgerTheme.foregroundFor(gradient!)
            : LedgerTheme.foregroundForColor(bg));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? bg : null,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        color: fg,
        size: iconSize,
      ),
    );
  }
}
