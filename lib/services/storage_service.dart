import 'dart:convert';
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
    await clearOfflineLocations();
    await clearOfflineTaskUpdates();
  }

  /// Saves an offline location coordinate.
  Future<void> saveOfflineLocation(Map<String, dynamic> location) async {
    final existingJson = await _storage.read(key: 'offline_locations');
    List<dynamic> list = [];
    if (existingJson != null) {
      try {
        list = jsonDecode(existingJson);
      } catch (e) {
        list = [];
      }
    }
    list.add(location);
    await _storage.write(key: 'offline_locations', value: jsonEncode(list));
  }

  /// Gets all offline locations.
  Future<List<Map<String, dynamic>>> getOfflineLocations() async {
    final existingJson = await _storage.read(key: 'offline_locations');
    if (existingJson == null) return [];
    try {
      final List<dynamic> list = jsonDecode(existingJson);
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clears all offline locations.
  Future<void> clearOfflineLocations() async {
    await _storage.delete(key: 'offline_locations');
  }

  /// Saves an offline task update.
  Future<void> saveOfflineTaskUpdate(Map<String, dynamic> update) async {
    final existingJson = await _storage.read(key: 'offline_task_updates');
    List<dynamic> list = [];
    if (existingJson != null) {
      try {
        list = jsonDecode(existingJson);
      } catch (e) {
        list = [];
      }
    }
    list.add(update);
    await _storage.write(key: 'offline_task_updates', value: jsonEncode(list));
  }

  /// Gets all offline task updates.
  Future<List<Map<String, dynamic>>> getOfflineTaskUpdates() async {
    final existingJson = await _storage.read(key: 'offline_task_updates');
    if (existingJson == null) return [];
    try {
      final List<dynamic> list = jsonDecode(existingJson);
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clears all offline task updates.
  Future<void> clearOfflineTaskUpdates() async {
    await _storage.delete(key: 'offline_task_updates');
  }

  /// Saves language preference.
  Future<void> saveLanguage(String lang) async {
    await _storage.write(key: 'app_lang', value: lang);
  }

  /// Gets language preference (defaults to 'tr').
  Future<String> getLanguage() async {
    final lang = await _storage.read(key: 'app_lang');
    return lang ?? 'tr';
  }
}
