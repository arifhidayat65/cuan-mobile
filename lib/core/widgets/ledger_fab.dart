import 'package:flutter/material.dart';

import '../theme/ledger_theme.dart';

/// Standard floating action button — accent bg, dark ink (M2).
class LedgerFab extends StatelessWidget {
  const LedgerFab({super.key, required this.onPressed, this.heroTag});

  final VoidCallback onPressed;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: LedgerTheme.accent,
      foregroundColor: LedgerTheme.onAccent,
      child: const Icon(Icons.add),
    );
  }
}
