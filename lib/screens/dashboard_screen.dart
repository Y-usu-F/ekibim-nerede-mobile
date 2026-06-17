import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'login_screen.dart';
import 'shift_screen.dart';
import 'task_list_screen.dart';
import 'leave_screen.dart';
import 'activity_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _user;
  String? _token;
  bool _loading = true;
  bool _isTracking = false;
  bool _onLeave = false;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
    _isTracking = LocationService().isTracking;
    LocalizationService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LocalizationService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAuthData() async {
    final storage = StorageService();
    final token = await storage.getToken();
    final userJson = await storage.getUser();

    bool onLeave = false;
    if (token != null) {
      try {
        final response = await ApiService().getShiftStatus();
        if (response.data != null && response.data['status'] == 'success') {
          onLeave = response.data['on_leave'] ?? false;
        }
      } catch (e) {
        print("Error fetching shift/leave status in dashboard: $e");
      }
    }

    if (mounted) {
      setState(() {
        _token = token;
        if (userJson != null) {
          _user = jsonDecode(userJson);
        }
        _onLeave = onLeave;
        _loading = false;
      });

      // Strict enforcement of KVKK: if today is an approved leave, background tracking is disabled.
      if (_onLeave) {
        LocationService().stopTracking();
        setState(() {
          _isTracking = false;
        });
      }
    }
  }

  Future<void> _toggleLocationTracking(bool value) async {
    final locationService = LocationService();
    if (value) {
      final success = await locationService.startTracking();
      if (success) {
        setState(() {
          _isTracking = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('location_sharing_active'))),
          );
        }
      } else {
        setState(() {
          _isTracking = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.currentLanguage == 'en' 
                ? 'Could not start location sharing. Please check permissions and GPS services.' 
                : 'Konum paylaşımı başlatılamadı. İzinleri ve GPS servislerini kontrol edin.')),
          );
        }
      }
    } else {
      locationService.stopTracking();
      setState(() {
        _isTracking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('location_sharing_inactive'))),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    LocationService().stopTracking(); // Stop background tracking on logout
    await StorageService().clearAuth();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  String _getRoleName(int roleId) {
    switch (roleId) {
      case 1:
        return t('role_admin');
      case 2:
        return t('role_manager');
      case 3:
      default:
        return t('role_user');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int roleId = _user?['role_id'] ?? 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('app_name')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String lang) async {
              await LocalizationService.setLanguage(lang);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'tr', child: Text('Türkçe (TR)')),
              const PopupMenuItem(value: 'en', child: Text('English (EN)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user?['name'] ?? (LocalizationService.currentLanguage == 'en' ? 'Username' : 'Kullanıcı Adı'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _user?['email'] ?? 'email@sirket.com',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        _getRoleName(roleId),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CONDITIONAL RBAC WIDGETS
            if (roleId == 1 || roleId == 2) ...[
              // Manager/Admin Controls
              Text(
                t('manager_actions'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_location_alt, color: Colors.blue),
                      title: Text(t('new_task')),
                      subtitle: Text(t('new_task_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // US-05: To be implemented
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.map_rounded, color: Colors.green),
                      title: Text(t('track_teams')),
                      subtitle: Text(t('track_teams_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // US-04: To be implemented
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Standard Field Worker Controls
              Text(
                t('worker_actions'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_onLeave) ...[
                Card(
                  color: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade300, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('on_leave_today'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t('leave_kvkk_warning'),
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.access_time_filled, color: Colors.teal),
                      title: Text(t('shift_clock')),
                      subtitle: Text(t('shift_clock_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShiftScreen()),
                        ).then((_) {
                          _loadAuthData();
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.my_location, color: Colors.purple),
                      title: Text(t('location_sharing_control')),
                      subtitle: Text(_onLeave 
                          ? t('location_sharing_leave')
                          : (_isTracking ? t('location_sharing_active') : t('location_sharing_inactive'))),
                      trailing: Switch(
                        value: _onLeave ? false : _isTracking,
                        activeThumbColor: Colors.purple,
                        activeTrackColor: Colors.purple.shade200,
                        onChanged: _onLeave ? null : _toggleLocationTracking,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.pending_actions, color: Colors.blue),
                      title: Text(t('log_activity')),
                      subtitle: Text(t('log_activity_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ActivityScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.beach_access, color: Colors.pink),
                      title: Text(t('leave_requests')),
                      subtitle: Text(t('leave_requests_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LeaveScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.assignment, color: Colors.amber),
                      title: Text(t('my_tasks')),
                      subtitle: Text(t('my_tasks_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TaskListScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              t('security_session'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('active_session_token'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 80),
                      width: double.infinity,
                      child: SingleChildScrollView(
                        child: Text(
                          _token ?? t('no_token'),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          t('rbac_active'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
