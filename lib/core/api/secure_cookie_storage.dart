import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [Storage] implementation for [PersistCookieJar] backed by
/// flutter_secure_storage (Android Keystore / iOS Keychain).
///
/// Cookie-jar keys (`.domains`, `.index`) are namespaced so they never
/// collide with other secure-storage entries the app may add later.
class SecureCookieStorage extends Storage {
  SecureCookieStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Prefix applied to every key written to secure storage.
  static const keyPrefix = 'cuan_cookie_jar.';

  final FlutterSecureStorage _secureStorage;

  String _namespaced(String key) => '$keyPrefix$key';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    // Secure storage needs no preparation.
  }

  @override
  Future<String?> read(String key) =>
      _secureStorage.read(key: _namespaced(key));

  @override
  Future<void> write(String key, String value) =>
      _secureStorage.write(key: _namespaced(key), value: value);

  @override
  Future<void> delete(String key) =>
      _secureStorage.delete(key: _namespaced(key));

  @override
  Future<void> deleteAll(List<String> keys) async {
    // Delete only the jar's keys — never wipe the whole secure storage,
    // which may hold unrelated secrets.
    for (final key in keys) {
      await delete(key);
    }
  }
}

/// One-time migration from the legacy plaintext [FileStorage] cookie dir
/// to [target]. Reads `.domains` / `.index` via [FileStorage], writes them
/// to [target], then deletes the legacy directory.
///
/// The legacy directory is only deleted when every read/write succeeds;
/// on any failure it is left in place so migration is retried next launch
/// (worst case the user re-logs in).
Future<void> migrateLegacyCookies({
  required String legacyDirPath,
  required SecureCookieStorage target,
}) async {
  final legacyDir = Directory(legacyDirPath);
  if (!await legacyDir.exists()) return;

  final legacy = FileStorage(legacyDirPath);
  await legacy.init(true, false);
  for (final key in ['.domains', '.index']) {
    final value = await legacy.read(key);
    if (value != null && value.isNotEmpty) {
      await target.write(key, value);
    }
  }
  await legacyDir.delete(recursive: true);
}
