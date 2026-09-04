import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// مدیریت کلیدهای رمزنگاری در Secure Storage سیستم‌عامل (بند ۷۲).
/// کلیدهای DB در Keystore/Keychain نگهداری می‌شوند؛ هرگز در کد Hard-code نمی‌شوند.
class KeyStore {
  final FlutterSecureStorage _storage;
  const KeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  /// کلید رمزنگاری DB (در صورت نبود ساخته و ذخیره می‌شود).
  Future<String> getOrCreateDatabaseKey() async {
    const keyName = 'wealth_os_db_key';
    final existing = await _storage.read(key: keyName);
    if (existing != null && existing.isNotEmpty) return existing;
    final key = _randomKey();
    await _storage.write(key: keyName, value: key);
    return key;
  }

  /// تولید کلید تصادفی امن (۳۲ بایت، Base64).
  String _randomKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Encode(bytes);
  }
}

String base64Encode(List<int> bytes) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final out = StringBuffer();
  for (var i = 0; i < bytes.length; i += 3) {
    final a = bytes[i];
    final b = i + 1 < bytes.length ? bytes[i + 1] : null;
    final c = i + 2 < bytes.length ? bytes[i + 2] : null;
    out.write(chars[a >> 2]);
    out.write(chars[((a & 3) << 4) | ((b ?? 0) >> 4)]);
    out.write(b == null ? '=' : chars[((b & 15) << 2) | ((c ?? 0) >> 6)]);
    out.write(c == null ? '=' : chars[c & 63]);
  }
  return out.toString();
}
