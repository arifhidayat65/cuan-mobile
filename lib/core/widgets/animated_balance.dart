import 'package:flutter/material.dart';
import '../utils/format.dart';
import '../theme/ledger_theme.dart';

/// Animated count-up balance in serif display type.
/// The "one big object" of the home screen.
class AnimatedBalance extends StatefulWidget {
  final double value;
  final Color? color;
  const AnimatedBalance({super.key, required this.value, this.color});

  @override
  State<AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<AnimatedBalance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    // Respect reduced motion.
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedBalance old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _anim.value;
      _anim = Tween<double>(begin: _from, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        idr(_anim.value),
        style: LedgerTheme.displaySerif(40, color: widget.color),
      ),
    );
  }
}
