import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/localization_service.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final _apiService = ApiService();
  bool _loading = true;
  bool _isClockedIn = false;
  bool _onLeave = false;
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
            _onLeave = data['on_leave'] ?? false;
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
          SnackBar(content: Text(LocalizationService.currentLanguage == 'en' 
              ? 'Error: Server connection error ($e)' 
              : 'Hata: Sunucu bağlantı hatası ($e)')),
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
          SnackBar(content: Text(LocalizationService.currentLanguage == 'en' 
              ? 'Could not retrieve location. Please enable location services.' 
              : 'Konum bilgisi alınamadı. Lütfen konum servislerini açın.')),
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
            SnackBar(content: Text(t('clock_in_success'))),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.currentLanguage == 'en'
              ? 'Clock-in failed: Unauthorized QR Code or data mismatch.'
              : 'Giriş başarısız: Yetkisiz QR Kod veya veri uyuşmazlığı.')),
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
          SnackBar(content: Text(LocalizationService.currentLanguage == 'en'
              ? 'Could not retrieve location. Please enable location services.'
              : 'Konum bilgisi alınamadı. Lütfen konum servislerini açın.')),
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
            SnackBar(content: Text(t('clock_out_success'))),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.currentLanguage == 'en' ? 'Clock-out failed: $e' : 'Çıkış yapılamadı: $e')),
        );
      }
    }
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(LocalizationService.currentLanguage == 'en' ? 'Scan QR Code' : 'QR Kodu Taratın')),
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
        title: Text(LocalizationService.currentLanguage == 'en' ? 'Shift Control Panel' : 'Mesai Kontrol Paneli'),
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
                    color: _onLeave 
                        ? Colors.orange.shade50 
                        : (_isClockedIn ? Colors.green.shade50 : Colors.red.shade50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            _onLeave 
                                ? Icons.beach_access 
                                : (_isClockedIn ? Icons.check_circle : Icons.error_outline),
                            size: 64,
                            color: _onLeave 
                                ? Colors.orange 
                                : (_isClockedIn ? Colors.green : Colors.red),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _onLeave 
                                ? (LocalizationService.currentLanguage == 'en' ? 'On Leave' : 'İzinli') 
                                : (_isClockedIn 
                                    ? (LocalizationService.currentLanguage == 'en' ? 'On Duty' : 'Mesaide') 
                                    : (LocalizationService.currentLanguage == 'en' ? 'Off Duty' : 'Mesai Dışı')),
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: _onLeave 
                                  ? Colors.orange.shade800 
                                  : (_isClockedIn ? Colors.green.shade800 : Colors.red.shade800)
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _onLeave 
                                ? (LocalizationService.currentLanguage == 'en' ? 'You have an approved leave request today.' : 'Bugün onaylı izniniz bulunmaktadır.') 
                                : (_isClockedIn 
                                    ? (LocalizationService.currentLanguage == 'en' ? 'Live shift duration is ticking below.' : 'Canlı mesai süresi aşağıda akmaktadır.') 
                                    : t('shift_start_hint')),
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
                            Text(
                              LocalizationService.currentLanguage == 'en' ? 'Work Duration' : 'Çalışma Süresi',
                              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1),
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
                                    '${LocalizationService.currentLanguage == 'en' ? 'Clock-in Location Registered' : 'Giriş Konumu Kayıtlı'}: ${_activeShift?['clock_in_latitude']?.toStringAsFixed(5)}, ${_activeShift?['clock_in_longitude']?.toStringAsFixed(5)}',
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
                  if (_onLeave) ...[
                    // When user is on leave, block clock-in entirely
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock, color: Colors.orange, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationService.currentLanguage == 'en' ? 'Shifts cannot be started on leave days.' : 'İzinli günlerde mesai başlatılamaz.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LocalizationService.currentLanguage == 'en'
                                ? 'Location tracking is disabled on leave days for KVKK compliance.'
                                : 'KVKK ve şirket politikaları gereği izinli olduğunuz günlerde konum takibi durdurulmuştur.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!_isClockedIn) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(t('scan_qr')),
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
                      label: Text(LocalizationService.currentLanguage == 'en' ? 'Start Shift (Simulator Mode)' : 'Mesaiyi Başlat (Simülatör Modu)'),
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
                      label: Text(t('end_shift')),
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
