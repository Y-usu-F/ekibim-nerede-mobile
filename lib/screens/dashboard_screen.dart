import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAuthData();
    _isTracking = LocationService().isTracking;
  }

  Future<void> _loadAuthData() async {
    final storage = StorageService();
    final token = await storage.getToken();
    final userJson = await storage.getUser();

    if (mounted) {
      setState(() {
        _token = token;
        if (userJson != null) {
          _user = jsonDecode(userJson);
        }
        _loading = false;
      });
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
            const SnackBar(content: Text('Konum paylaşımı başlatıldı.')),
          );
        }
      } else {
        setState(() {
          _isTracking = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum paylaşımı başlatılamadı. İzinleri ve GPS servislerini kontrol edin.')),
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
          const SnackBar(content: Text('Konum paylaşımı durduruldu.')),
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
        return 'Sistem Yöneticisi (Admin)';
      case 2:
        return 'Yönetici (Manager)';
      case 3:
      default:
        return 'Saha Personeli (User)';
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
        title: const Text('Ekibim Nerede - Portal'),
        actions: [
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
                      _user?['name'] ?? 'Kullanıcı Adı',
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
              const Text(
                'Yönetici İşlemleri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_location_alt, color: Colors.blue),
                      title: const Text('Yeni Görev Ata'),
                      subtitle: const Text('Harita üzerinden sahaya yeni görev ekle'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // US-05: To be implemented
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.map_rounded, color: Colors.green),
                      title: const Text('Saha Ekiplerini İzle'),
                      subtitle: const Text('Canlı konum haritasını görüntüle'),
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
              const Text(
                'Saha İşlemleri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.my_location, color: Colors.purple),
                      title: const Text('Konum Paylaşımı Kontrolü'),
                      subtitle: Text(_isTracking ? 'Konum paylaşımı AKTİF' : 'Konum paylaşımı KAPALI'),
                      trailing: Switch(
                        value: _isTracking,
                        activeThumbColor: Colors.purple,
                        activeTrackColor: Colors.purple.shade200,
                        onChanged: _toggleLocationTracking,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.assignment, color: Colors.amber),
                      title: const Text('Bana Atanan Görevler'),
                      subtitle: const Text('Aktif görev listesini ve detaylarını gör'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // US-06: To be implemented
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Güvenlik ve Oturum',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktif Oturum Tokeni (JWT)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                          _token ?? 'Token yok',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Rol Tabanlı Erişim Koruma Aktif',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
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
