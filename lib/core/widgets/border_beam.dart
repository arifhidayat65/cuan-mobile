import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ledger_theme.dart';

/// Rotating beam border — the signature AI accent (Magic UI: BorderBeam).
///
/// Discipline: used ONLY on the AI icon. Everywhere else the accent stays
/// static. Respects reduced motion (renders a static ring instead).
class BorderBeam extends StatefulWidget {
  const BorderBeam({
    super.key,
    required this.child,
    this.size = 36,
    this.beamColor = LedgerTheme.accent,
    this.trackAlpha = 0.18,
    this.duration = const Duration(seconds: 3),
  });

  final Widget child;
  final double size;
  final Color beamColor;
  final double trackAlpha;
  final Duration duration;

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.beamColor.withValues(alpha: widget.trackAlpha),
            width: 1.5,
          ),
        ),
        child: Center(child: widget.child),
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => CustomPaint(
          painter: _BeamPainter(
            progress: _c.value,
            beamColor: widget.beamColor,
            trackAlpha: widget.trackAlpha,
          ),
          child: child,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  _BeamPainter({
    required this.progress,
    required this.beamColor,
    required this.trackAlpha,
  });

  final double progress;
  final Color beamColor;
  final double trackAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Subtle full track so the ring reads even where the beam isn't.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = beamColor.withValues(alpha: trackAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // The beam: a short bright arc sweeping around the ring.
    final start = progress * 2 * math.pi - math.pi / 2;
    const sweep = math.pi / 3.2; // ~56 degrees
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = beamColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = beamColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BeamPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.beamColor != beamColor ||
      oldDelegate.trackAlpha != trackAlpha;
}
