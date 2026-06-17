import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../services/localization_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _apiService = ApiService();
  bool _loading = true;
  List<dynamic> _tasks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Automatically attempt syncing any offline data (locations/tasks) when user loads/refreshes tasks
    await SyncService().syncOfflineData();

    try {
      final response = await _apiService.getTasks();
      if (response.data != null && response.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _tasks = response.data['data'] ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = LocalizationService.currentLanguage == 'en' ? 'Could not load tasks.' : 'Görevler yüklenemedi.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = LocalizationService.currentLanguage == 'en' ? 'Connection error: Could not fetch task list.' : 'Bağlantı hatası: Görev listesi alınamadı.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateTaskStatus(int taskId, String newStatus) async {
    Navigator.of(context).pop(); // Close detail sheet
    setState(() => _loading = true);

    try {
      final response = await _apiService.updateTaskStatus(taskId, newStatus);
      if (response.data != null && response.data['status'] == 'success') {
        await _fetchTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.currentLanguage == 'en' ? 'Task status updated.' : 'Görev durumu güncellendi.')),
          );
        }
      }
    } catch (e) {
      // Offline fallback: cache status update locally in storage
      await StorageService().saveOfflineTaskUpdate({
        'task_id': taskId,
        'status': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          // Optimistically update status in local UI so worker sees progress immediately
          for (var task in _tasks) {
            if (task['id'] == taskId) {
              task['status'] = newStatus;
            }
          }
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.currentLanguage == 'en' 
                ? 'Offline Mode: Update saved, will sync when internet is connected.' 
                : 'Çevrimdışı Mod: Güncelleme kaydedildi, internet bağlandığında senkronize edilecek.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'todo':
      default:
        return Colors.amber;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'done':
        return t('status_done');
      case 'in_progress':
        return t('status_in_progress');
      case 'todo':
      default:
        return t('status_todo');
    }
  }

  void _showTaskDetail(Map<String, dynamic> task) {
    final status = task['status'];
    final taskId = task['id'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task['title'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(
                      _getStatusLabel(status),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(status),
                  )
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                t('task_detail'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                task['description'] != null && task['description'].toString().isNotEmpty
                    ? task['description']
                    : (LocalizationService.currentLanguage == 'en' ? 'No description specified.' : 'Açıklama belirtilmedi.'),
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Due Date & Location
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${LocalizationService.currentLanguage == 'en' ? 'Due Date' : 'Teslim Tarihi'}: ${task['due_date']}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${LocalizationService.currentLanguage == 'en' ? 'Location' : 'Konum'}: ${task['latitude']}, ${task['longitude']}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status Transition Buttons
              if (status == 'todo') ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text(LocalizationService.currentLanguage == 'en' ? 'Start Work' : 'Çalışmayı Başlat'),
                  onPressed: () => _updateTaskStatus(taskId, 'in_progress'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else if (status == 'in_progress') ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(LocalizationService.currentLanguage == 'en' ? 'Complete Task' : 'Görevi Tamamla'),
                  onPressed: () => _updateTaskStatus(taskId, 'done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: null,
                  child: Text(LocalizationService.currentLanguage == 'en' ? 'Task Completed' : 'Görev Tamamlanmış'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('my_tasks')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasks,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 15), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTasks,
                          child: Text(LocalizationService.currentLanguage == 'en' ? 'Try Again' : 'Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : _tasks.isEmpty
                  ? Center(
                      child: Text(
                        t('no_tasks'),
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final status = task['status'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              task['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  task['description'] != null && task['description'].toString().isNotEmpty
                                      ? task['description']
                                      : (LocalizationService.currentLanguage == 'en' ? 'No description specified.' : 'Açıklama belirtilmedi.'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${t('due_date')}: ${task['due_date']}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    )
                                  ],
                                )
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withAlpha(38),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _getStatusColor(status).withAlpha(128)),
                                  ),
                                  child: Text(
                                    _getStatusLabel(status),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showTaskDetail(task),
                          ),
                        );
                      },
                    ),
    );
  }
}
