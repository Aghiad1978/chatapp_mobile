import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._privateConstructor();
  static final SecureStorage container = SecureStorage._privateConstructor();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> writeSecureStorage(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecureStorage(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecureStorage(String key) async {
    await _secureStorage.delete(key: key);
    print("Done deleteing");
  }
}
