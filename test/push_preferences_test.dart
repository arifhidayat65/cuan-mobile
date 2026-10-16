import 'package:cuan_mobile/core/notifications/push_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default is enabled when never set', () async {
    expect(await PushPreferences().isEnabled(), isTrue);
  });

  test('persists disabled across reads', () async {
    final prefs = PushPreferences();
    await prefs.setEnabled(false);
    expect(await prefs.isEnabled(), isFalse);
    // New instance reads the same persisted value.
    expect(await PushPreferences().isEnabled(), isFalse);
  });

  test('persists re-enabled value', () async {
    final prefs = PushPreferences();
    await prefs.setEnabled(false);
    await prefs.setEnabled(true);
    expect(await PushPreferences().isEnabled(), isTrue);
  });
}
