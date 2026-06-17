import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
            _error = 'Görevler yüklenemedi.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bağlantı hatası: Görev listesi alınamadı.';
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
            const SnackBar(content: Text('Görev durumu güncellendi.')),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Durum güncellenemedi: $e')),
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
        return 'Tamamlandı';
      case 'in_progress':
        return 'Yapılıyor';
      case 'todo':
      default:
        return 'Yapılacak';
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
              const Text(
                'Görev Detayları',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                task['description'] != null && task['description'].toString().isNotEmpty
                    ? task['description']
                    : 'Açıklama belirtilmedi.',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Due Date & Location
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Teslim Tarihi: ${task['due_date']}',
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
                    'Konum: ${task['latitude']}, ${task['longitude']}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status Transition Buttons
              if (status == 'todo') ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Çalışmayı Başlat'),
                  onPressed: () => _updateTaskStatus(taskId, 'in_progress'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else if (status == 'in_progress') ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Görevi Tamamla'),
                  onPressed: () => _updateTaskStatus(taskId, 'done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Görev Tamamlanmış'),
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
        title: const Text('Bana Atanan Görevler'),
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
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : _tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Size atanmış herhangi bir görev bulunamadı.',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
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
                                      : 'Açıklama belirtilmedi.',
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
                                      'Bitiş: ${task['due_date']}',
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
