import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/ledger_theme.dart';
import 'features/accounts/bloc/accounts_cubit.dart';
import 'features/accounts/data/accounts_repository.dart';
import 'features/activity/bloc/activity_cubit.dart';
import 'features/activity/data/activity_repository.dart';
import 'features/assistant/bloc/assistant_cubit.dart';
import 'features/assistant/data/assistant_repository.dart';
import 'features/auth/bloc/app_gate_cubit.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/app_lock_screen.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/budgets/bloc/budgets_cubit.dart';
import 'features/budgets/data/budgets_repository.dart';
import 'features/home/bloc/home_cubit.dart';
import 'features/home/data/home_repository.dart';
import 'features/settings/bloc/settings_cubit.dart';
import 'features/settings/bloc/theme_cubit.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/shell/bloc/navigation_cubit.dart';

/// Cuan root widget — dependency injection + MaterialApp.
///
/// Repositories wrap [CuanApi]; blocs/cubits consume repositories.
/// [AuthBloc] starts the session check on creation.
class CuanApp extends StatelessWidget {
  const CuanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => HomeRepository()),
        RepositoryProvider(create: (_) => ActivityRepository()),
        RepositoryProvider(create: (_) => AssistantRepository()),
        RepositoryProvider(create: (_) => BudgetsRepository()),
        RepositoryProvider(create: (_) => AccountsRepository()),
        RepositoryProvider(create: (_) => SettingsRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (c) =>
                AuthBloc(c.read<AuthRepository>())..add(const AuthAppStarted()),
          ),
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(
            create: (c) => HomeCubit(c.read<HomeRepository>()),
          ),
          BlocProvider(
            create: (c) => ActivityCubit(c.read<ActivityRepository>()),
          ),
          BlocProvider(
            create: (c) => AssistantCubit(c.read<AssistantRepository>()),
          ),
          BlocProvider(
            create: (c) => BudgetsCubit(c.read<BudgetsRepository>()),
          ),
          BlocProvider(
            create: (c) => AccountsCubit(c.read<AccountsRepository>()),
          ),
          BlocProvider(
            create: (c) => SettingsCubit(c.read<SettingsRepository>()),
          ),
          BlocProvider(create: (_) => ThemeCubit()..load()),
          BlocProvider(create: (_) => AppGateCubit()..checkGates()),
        ],
        child: BlocBuilder<ThemeCubit, bool>(
          builder: (context, isDark) {
            return BlocListener<ThemeCubit, bool>(
              // C1: keep status/nav bar readable in both modes.
              listener: (_, dark) {
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness:
                        dark ? Brightness.light : Brightness.dark,
                    systemNavigationBarColor: LedgerTheme.bg,
                    systemNavigationBarIconBrightness:
                        dark ? Brightness.light : Brightness.dark,
                  ),
                );
              },
              child: MaterialApp(
                title: 'Cuan',
                debugShowCheckedModeBanner: false,
                theme: LedgerTheme.current,
                home: const _AppRoot(),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Root that gates behind onboarding, biometric lock, then auth.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppGateCubit, AppGateState>(
      builder: (context, state) {
        if (state.checking) {
          return Scaffold(
            backgroundColor: LedgerTheme.bg,
            body: Center(
              child: CircularProgressIndicator(color: LedgerTheme.accent),
            ),
          );
        }
        if (state.showOnboarding) {
          return OnboardingScreen(
            onDone: () =>
                context.read<AppGateCubit>().completeOnboarding(),
          );
        }
        if (state.locked) {
          return AppLockScreen(
            onUnlocked: () => context.read<AppGateCubit>().unlock(),
          );
        }
        return const AuthGate();
      },
    );
  }
}
