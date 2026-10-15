import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../bloc/app_lock_cubit.dart';

/// App lock screen — shown on startup when biometric lock is enabled.
class AppLockScreen extends StatelessWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppLockCubit(),
      child: Builder(
        builder: (ctx) {
          // Auto-attempt on first build.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final ok =
                await ctx.read<AppLockCubit>().tryUnlock();
            if (ok) onUnlocked();
          });
          return BlocBuilder<AppLockCubit, AppLockState>(
            builder: (context, state) => Scaffold(
              backgroundColor: LedgerTheme.bg,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: FadeIn(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GradientAvatar(
                            icon: Icons.fingerprint,
                            gradient: LedgerTheme.accentGradient,
                            size: 88,
                            iconSize: 44,
                            radius: 44,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Cuan terkunci',
                            style: TextStyle(
                              color: LedgerTheme.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Verifikasi biometrik untuk membuka',
                            style:
                                TextStyle(color: LedgerTheme.muted),
                          ),
                          if (state.failed) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Verifikasi gagal. Coba lagi.',
                              style: TextStyle(
                                  color: LedgerTheme.rose, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () async {
                              final ok = await ctx
                                  .read<AppLockCubit>()
                                  .tryUnlock();
                              if (ok) onUnlocked();
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Buka dengan biometrik'),
                            style: FilledButton.styleFrom(
                              backgroundColor: LedgerTheme.accent,
                              foregroundColor: LedgerTheme.onAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => SystemNavigator.pop(),
                            child: Text(
                              'Tutup aplikasi',
                              style:
                                  TextStyle(color: LedgerTheme.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
