import 'package:cuan_mobile/core/api/auth_state_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthStateCache', () {
    test('read returns null when never written', () async {
      expect(await AuthStateCache().read(), isNull);
    });

    test('write true then read returns true', () async {
      final cache = AuthStateCache();

      await cache.write(true);

      expect(await cache.read(), isTrue);
    });

    test('write false then read returns false', () async {
      final cache = AuthStateCache();

      await cache.write(false);

      expect(await cache.read(), isFalse);
    });

    test('clear marks the user as logged out', () async {
      final cache = AuthStateCache();
      await cache.write(true);

      await cache.clear();

      expect(await cache.read(), isFalse);
    });

    test('state persists across instances (app restart)', () async {
      await AuthStateCache().write(true);

      // Brand-new instance over the same (mocked) prefs backend.
      expect(await AuthStateCache().read(), isTrue);
    });
  });
}
