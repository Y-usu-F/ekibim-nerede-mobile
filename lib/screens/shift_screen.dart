import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final _apiService = ApiService();
  bool _loading = true;
  bool _isClockedIn = false;
  Map<String, dynamic>? _activeShift;
  Timer? _timer;
  String _elapsedTime = "00:00:00";

  @override
  void initState() {
    super.initState();
    _checkShiftStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkShiftStatus() async {
    setState(() => _loading = true);
    try {
      final response = await _apiService.getShiftStatus();
      if (response.data != null && response.data['status'] == 'success') {
        final data = response.data;
        if (mounted) {
          setState(() {
            _isClockedIn = data['is_clocked_in'];
            _activeShift = data['active_shift'];
            _loading = false;
          });
          if (_isClockedIn) {
            _startTimer();
          } else {
            _timer?.cancel();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: Sunucu bağlantı hatası ($e)')),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_activeShift == null || _activeShift!['clock_in'] == null) return;
    
    final clockInTime = DateTime.parse(_activeShift!['clock_in']).toLocal();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final difference = DateTime.now().difference(clockInTime);
      final hours = difference.inHours.toString().padLeft(2, '0');
      final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
      
      if (mounted) {
        setState(() {
          _elapsedTime = "$hours:$minutes:$seconds";
        });
      }
    });
  }

  Future<loc.LocationData?> _getCurrentLocation() async {
    final location = loc.Location();
    
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return null;
    }

    try {
      return await location.getLocation();
    } catch (e) {
      print("Location fetch error: $e");
      return null;
    }
  }

  Future<void> _handleClockIn(String qrData) async {
    setState(() => _loading = true);
    final locationData = await _getCurrentLocation();
    if (locationData == null) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum bilgisi alınamadı. Lütfen konum servislerini açın.')),
        );
      }
      return;
    }

    try {
      final response = await _apiService.clockIn(
        qrData, 
        locationData.latitude!, 
        locationData.longitude!
      );

      if (response.data != null && response.data['status'] == 'success') {
        // Automatically trigger live background location tracking upon clock-in
        await LocationService().startTracking();
        
        await _checkShiftStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesai başarıyla başlatıldı.')),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş başarısız: Yetkisiz QR Kod veya veri uyuşmazlığı.')),
        );
      }
    }
  }

  Future<void> _handleClockOut() async {
    setState(() => _loading = true);
    final locationData = await _getCurrentLocation();
    if (locationData == null) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum bilgisi alınamadı. Lütfen konum servislerini açın.')),
        );
      }
      return;
    }

    try {
      final response = await _apiService.clockOut(
        locationData.latitude!, 
        locationData.longitude!
      );

      if (response.data != null && response.data['status'] == 'success') {
        // Stop background tracking upon clock-out for privacy (KVKK compliance)
        LocationService().stopTracking();
        
        await _checkShiftStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesai sonlandırıldı.')),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılamadı: $e')),
        );
      }
    }
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('QR Kodu Taratın')),
          body: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final scannedData = barcodes.first.rawValue!;
                Navigator.of(context).pop(scannedData);
              }
            },
          ),
        ),
      ),
    ).then((scannedValue) {
      if (scannedValue != null && scannedValue is String) {
        _handleClockIn(scannedValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesai Kontrol Paneli'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Header Card
                  Card(
                    elevation: 4,
                    color: _isClockedIn ? Colors.green.shade50 : Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            _isClockedIn ? Icons.check_circle : Icons.error_outline,
                            size: 64,
                            color: _isClockedIn ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isClockedIn ? 'Mesaide' : 'Mesai Dışı',
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: _isClockedIn ? Colors.green.shade800 : Colors.red.shade800
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isClockedIn 
                                ? 'Canlı mesai süresi aşağıda akmaktadır.' 
                                : 'Mesaiyi başlatmak için iş yeri QR kodunu taratın.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timer Card
                  if (_isClockedIn) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              'Çalışma Süresi',
                              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _elapsedTime,
                              style: const TextStyle(
                                fontSize: 42, 
                                fontWeight: FontWeight.bold, 
                                fontFamily: 'monospace'
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Giriş Konumu Kayıtlı: ${_activeShift?['clock_in_latitude']?.toStringAsFixed(5)}, ${_activeShift?['clock_in_longitude']?.toStringAsFixed(5)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions Section
                  if (!_isClockedIn) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('QR Kod Okutarak Başlat'),
                      onPressed: _openQrScanner,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Emulators & Test Mocking Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Mesaiyi Başlat (Simülatör Modu)'),
                      onPressed: () => _handleClockIn('ekibim_nerede_office_location_1'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.purple),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.purple,
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop_circle),
                      label: const Text('Mesaiyi Bitir'),
                      onPressed: _handleClockOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
