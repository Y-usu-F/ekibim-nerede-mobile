import 'package:dio/dio.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _apiService = ApiService();
  final _storage = StorageService();
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Trigger sync for offline location history and task updates.
  Future<void> syncOfflineData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Sync Locations
      final locations = await _storage.getOfflineLocations();
      if (locations.isNotEmpty) {
        try {
          final response = await _apiService.saveLocationBulk(locations);
          if (response.statusCode == 200 || response.statusCode == 201) {
            await _storage.clearOfflineLocations();
            print("Offline locations synced successfully.");
          }
        } on DioException catch (e) {
          print("Failed to sync offline locations: $e");
          if (e.response != null && e.response!.statusCode != null) {
            final code = e.response!.statusCode!;
            if (code >= 400 && code < 500 && code != 401) {
              // Bad request format, clear it
              await _storage.clearOfflineLocations();
            }
          }
        } catch (e) {
          print("Error during location sync: $e");
        }
      }

      // 2. Sync Task Updates
      final taskUpdates = await _storage.getOfflineTaskUpdates();
      if (taskUpdates.isNotEmpty) {
        final List<Map<String, dynamic>> remainingUpdates = [];
        for (final update in taskUpdates) {
          final taskId = update['task_id'];
          final status = update['status'];
          if (taskId == null || status == null) continue;

          try {
            final response = await _apiService.updateTaskStatus(taskId, status);
            if (response.statusCode == 200 || response.statusCode == 201) {
              print("Offline task update for task $taskId synced successfully.");
            } else {
              remainingUpdates.add(update);
            }
          } on DioException catch (e) {
            print("Failed to sync task update for task $taskId: $e");
            if (e.response != null && e.response!.statusCode != null) {
              final code = e.response!.statusCode!;
              if (code >= 400 && code < 500 && code != 401) {
                // Client error, discard this update to prevent infinite loops
                print("Discarding invalid task update for task $taskId.");
              } else {
                remainingUpdates.add(update);
              }
            } else {
              remainingUpdates.add(update);
            }
          } catch (e) {
            print("Error syncing task $taskId: $e");
            remainingUpdates.add(update);
          }
        }

        if (remainingUpdates.isEmpty) {
          await _storage.clearOfflineTaskUpdates();
        } else {
          // Update the cache with remaining updates
          await _storage.clearOfflineTaskUpdates();
          for (final rem in remainingUpdates) {
            await _storage.saveOfflineTaskUpdate(rem);
          }
        }
      }
    } catch (e) {
      print("Sync process encountered error: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
