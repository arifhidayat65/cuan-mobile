import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/ledger_theme.dart';
import '../../../core/widgets/fade_in.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../bloc/onboarding_cubit.dart';

/// First-run onboarding — 3 pages introducing Cuan.
class OnboardingScreen extends StatelessWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  static const _key = 'onboarding_done';

  static Future<bool> get isDone async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static const _pages = [
    _OnboardData(
      icon: Icons.auto_awesome,
      title: 'Catat dengan Chat AI',
      desc:
          'Ceritakan pengeluaranmu dengan bahasa sehari-hari, AI otomatis mencatatnya ke kategori yang tepat.',
    ),
    _OnboardData(
      icon: Icons.pie_chart_outline,
      title: 'Budget Terkendali',
      desc:
          'Atur budget bulanan per kategori dan dapatkan peringatan sebelum kebablasan.',
    ),
    _OnboardData(
      icon: Icons.insights_outlined,
      title: 'Insight Proaktif',
      desc:
          'AI memantau pola pengeluaranmu dan memberi saran hemat yang realistis.',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    final pageCtrl = PageController();
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: Builder(
        builder: (ctx) => Scaffold(
          backgroundColor: LedgerTheme.bg,
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Lewati',
                      style: LedgerTheme.bodyMedium
                          .copyWith(color: LedgerTheme.muted),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: pageCtrl,
                    onPageChanged: (i) =>
                        ctx.read<OnboardingCubit>().setPage(i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => FadeIn(
                      key: ValueKey('onboard_$i'),
                      child: _OnboardPage(data: _pages[i]),
                    ),
                  ),
                ),
                BlocBuilder<OnboardingCubit, int>(
                  builder: (context, page) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: page == i
                              ? LedgerTheme.accent
                              : LedgerTheme.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: BlocBuilder<OnboardingCubit, int>(
                      builder: (context, page) => FilledButton(
                        onPressed: () {
                          if (page < _pages.length - 1) {
                            pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          } else {
                            _finish();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: LedgerTheme.accent,
                          foregroundColor: LedgerTheme.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          page < _pages.length - 1 ? 'Lanjut' : 'Mulai',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final String title;
  final String desc;
  const _OnboardData({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Single brand treatment — one identity, not rainbow.
          GradientAvatar(
            icon: data.icon,
            gradient: LedgerTheme.accentGradient,
            size: 120,
            iconSize: 56,
            radius: 60,
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: LedgerTheme.displaySerif(26, weight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            data.desc,
            textAlign: TextAlign.center,
            style: LedgerTheme.bodyMedium.copyWith(
              color: LedgerTheme.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
