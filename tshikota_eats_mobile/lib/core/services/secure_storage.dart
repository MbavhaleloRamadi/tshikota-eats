import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Business ID cache (avoid token refresh on every screen)
  static Future<void> saveBusinessId(String id) =>
      _storage.write(key: 'business_id', value: id);

  static Future<String?> getBusinessId() => _storage.read(key: 'business_id');

  // User role cache
  static Future<void> saveUserRole(String role) =>
      _storage.write(key: 'user_role', value: role);

  static Future<String?> getUserRole() => _storage.read(key: 'user_role');

  // Dashboard widget preferences
  static Future<void> saveDashboardConfig(String json) =>
      _storage.write(key: 'dashboard_config', value: json);

  static Future<String?> getDashboardConfig() =>
      _storage.read(key: 'dashboard_config');

  // Clear all on logout
  static Future<void> clearAll() => _storage.deleteAll();
}
