import 'package:cuan_mobile/core/notifications/notification_service.dart';
import 'package:cuan_mobile/features/settings/bloc/settings_cubit.dart';
import 'package:cuan_mobile/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake push controller — records calls without touching Firebase.
class _FakePush extends NotificationService {
  bool enabled = true;
  int setCalls = 0;

  @override
  Future<bool> isPushEnabled() async => enabled;

  @override
  Future<void> setPushEnabled(bool value) async {
    enabled = value;
    setCalls++;
  }
}

void main() {
  test('toggleNotifications(false) persists and applies the change', () async {
    final push = _FakePush();
    final cubit = SettingsCubit(SettingsRepository(), push: push);

    await cubit.toggleNotifications(false);

    expect(cubit.state.notificationsEnabled, isFalse);
    expect(push.setCalls, 1);
    expect(push.enabled, isFalse);
    await cubit.close();
  });

  test('toggleNotifications(true) re-enables push', () async {
    final push = _FakePush()..enabled = false;
    final cubit = SettingsCubit(SettingsRepository(), push: push);

    await cubit.toggleNotifications(true);

    expect(cubit.state.notificationsEnabled, isTrue);
    expect(push.enabled, isTrue);
    await cubit.close();
  });
}
