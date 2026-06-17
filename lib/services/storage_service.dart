import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = const FlutterSecureStorage();

  /// Saves the JWT token to secure storage.
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  /// Reads the JWT token from secure storage.
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// Deletes the JWT token from secure storage.
  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  /// Saves the serialized user model.
  Future<void> saveUser(String userJson) async {
    await _storage.write(key: 'user_profile', value: userJson);
  }

  /// Reads the serialized user profile.
  Future<String?> getUser() async {
    return await _storage.read(key: 'user_profile');
  }

  /// Clears all stored data (logout).
  Future<void> clearAuth() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_profile');
  }
}
