import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cuan_mobile/core/api/secure_cookie_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory backing store for the mocked flutter_secure_storage channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};
  final writtenKeys = <String>[];

  setUp(() {
    store.clear();
    writtenKeys.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'read':
          return store[call.arguments['key'] as String];
        case 'write':
          final key = call.arguments['key'] as String;
          final value = call.arguments['value'] as String?;
          writtenKeys.add(key);
          if (value == null) {
            store.remove(key);
          } else {
            store[key] = value;
          }
          return null;
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SecureCookieStorage', () {
    test('write then read returns the value', () async {
      final storage = SecureCookieStorage();
      await storage.init(true, false);

      await storage.write('.domains', '{"example.com":{}}');

      expect(await storage.read('.domains'), '{"example.com":{}}');
    });

    test('read of missing key returns null', () async {
      final storage = SecureCookieStorage();
      await storage.init(true, false);

      expect(await storage.read('.nope'), isNull);
    });

    test('delete removes the value', () async {
      final storage = SecureCookieStorage();
      await storage.init(true, false);
      await storage.write('.index', '["a.com"]');

      await storage.delete('.index');

      expect(await storage.read('.index'), isNull);
    });

    test('deleteAll removes only the given keys', () async {
      final storage = SecureCookieStorage();
      await storage.init(true, false);
      await storage.write('.domains', 'd');
      await storage.write('.index', 'i');

      await storage.deleteAll(['.domains']);

      expect(await storage.read('.domains'), isNull);
      expect(await storage.read('.index'), 'i');
    });

    test('keys are namespaced in secure storage', () async {
      final storage = SecureCookieStorage();
      await storage.init(true, false);

      await storage.write('.domains', 'x');

      expect(writtenKeys, hasLength(1));
      expect(writtenKeys.single, isNot('.domains'));
      expect(writtenKeys.single, contains('.domains'));
    });

    test('cookies persist across storage instances (app restart)', () async {
      final first = SecureCookieStorage();
      await first.init(true, false);
      await first.write('.domains', '{"example.com":{}}');
      await first.write('.index', '["example.com"]');

      // Simulate app restart: a brand-new storage instance over the same
      // (mocked) secure storage backend.
      final second = SecureCookieStorage();
      await second.init(true, false);

      expect(await second.read('.domains'), '{"example.com":{}}');
      expect(await second.read('.index'), '["example.com"]');
    });
  });

  group('migrateLegacyCookies', () {
    test('imports .domains and .index then removes legacy dir', () async {
      final tempDir = await Directory.systemTemp.createTemp('cuan_cookies');
      final legacyDirPath = '${tempDir.path}/cookies';

      // Simulate the old app: write via FileStorage exactly as CuanApi did
      // (FileStorage nests files under ie0_ps1/ — the test must not assume
      // a flat layout).
      final legacy = FileStorage(legacyDirPath);
      await legacy.init(true, false);
      await legacy.write('.domains', '{"a.com":{}}');
      await legacy.write('.index', '["a.com"]');

      final storage = SecureCookieStorage();
      await migrateLegacyCookies(
        legacyDirPath: legacyDirPath,
        target: storage,
      );

      expect(await storage.read('.domains'), '{"a.com":{}}');
      expect(await storage.read('.index'), '["a.com"]');
      expect(await Directory(legacyDirPath).exists(), isFalse);

      await tempDir.delete(recursive: true);
    });

    test('does nothing when legacy dir is absent', () async {
      final tempDir = await Directory.systemTemp.createTemp('cuan_cookies');
      final storage = SecureCookieStorage();

      await migrateLegacyCookies(
        legacyDirPath: '${tempDir.path}/cookies',
        target: storage,
      );

      expect(await storage.read('.domains'), isNull);
      expect(await storage.read('.index'), isNull);

      await tempDir.delete(recursive: true);
    });
  });
}
