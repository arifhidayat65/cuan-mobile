import 'package:flutter/material.dart';

import '../theme/ledger_theme.dart';

/// Designed error state: icon, headline, message, retry button.
/// Mirrors [EmptyState] so failures look intentional, not broken.
class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LedgerTheme.radiusCard),
          border: Border.all(color: LedgerTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: LedgerTheme.surface2,
                borderRadius:
                    BorderRadius.circular(LedgerTheme.radiusAvatar),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                color: LedgerTheme.muted,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: LedgerTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LedgerTheme.bodyMedium.copyWith(
                color: LedgerTheme.muted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LedgerTheme.accent,
                foregroundColor: LedgerTheme.onAccent,
              ),
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
