import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import '../services/api_service.dart';
import '../services/localization_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _apiService = ApiService();
  bool _loading = true;
  List<dynamic> _activities = [];
  String? _error;

  // Form controllers and state
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'customer_visit';
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  final List<String> _types = [
    'customer_visit',
    'assembly',
    'break',
    'maintenance',
    'journey',
    'other',
  ];

  String _getTypeLabel(String type) {
    switch (type) {
      case 'customer_visit':
        return t('customer_visit');
      case 'assembly':
        return t('assembly');
      case 'break':
        return t('break');
      case 'maintenance':
        return t('maintenance');
      case 'journey':
        return t('journey');
      case 'other':
      default:
        return t('other');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getMyActivities();
      if (response.data != null && response.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _activities = response.data['data'] ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = LocalizationService.currentLanguage == 'en' ? 'Could not load activities.' : 'Aviteler yüklenemedi.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = LocalizationService.currentLanguage == 'en' ? 'Connection error: Could not fetch activity history.' : 'Bağlantı hatası: Aktivite geçmişi alınamadı.';
          _loading = false;
        });
      }
    }
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

  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // Get current GPS coordinates
    final locationData = await _getCurrentLocation();
    if (locationData == null) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService.currentLanguage == 'en'
              ? 'Could not retrieve location. Please check GPS services and permissions.'
              : 'Konum bilgisi alınamadı. GPS servislerini ve izinlerini kontrol edin.')),
        );
      }
      return;
    }

    try {
      final response = await _apiService.createActivity(
        type: _selectedType,
        description: _descriptionController.text,
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
      );

      if (response.data != null && response.data['status'] == 'success') {
        setState(() {
          _selectedType = 'customer_visit';
          _descriptionController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('activity_saved')),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchActivities();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService.currentLanguage == 'en' ? 'Error: Could not save activity' : 'Hata: Aktivite kaydedilemedi'} ($e)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showNewActivityDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24.0,
                right: 24.0,
                top: 24.0,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('new_activity'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Type dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: t('activity_type'),
                          border: const OutlineInputBorder(),
                        ),
                        items: _types.map((typeKey) {
                          return DropdownMenuItem<String>(
                            value: typeKey,
                            child: Text(_getTypeLabel(typeKey)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              _selectedType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: t('activity_desc'),
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return t('no_description_validation');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _submitActivity();
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const CircularProgressIndicator()
                            : Text(t('save_activity'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'customer_visit':
        return Colors.blue;
      case 'assembly':
        return Colors.green;
      case 'break':
        return Colors.orange;
      case 'maintenance':
        return Colors.indigo;
      case 'journey':
        return Colors.cyan;
      case 'other':
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'customer_visit':
        return Icons.business;
      case 'assembly':
        return Icons.build;
      case 'break':
        return Icons.coffee;
      case 'maintenance':
        return Icons.handyman;
      case 'journey':
        return Icons.directions_car;
      case 'other':
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('activities_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActivities,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewActivityDialog,
        icon: const Icon(Icons.add),
        label: Text(LocalizationService.currentLanguage == 'en' ? 'Add Activity' : 'Aktivite Ekle'),
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
                          onPressed: _fetchActivities,
                          child: Text(LocalizationService.currentLanguage == 'en' ? 'Try Again' : 'Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : _activities.isEmpty
                  ? Center(
                      child: Text(
                        LocalizationService.currentLanguage == 'en' ? 'You have not logged any activity today.' : 'Henüz bugün için bir aktivite kaydı girmediniz.',
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final act = _activities[index];
                        final type = act['type'] ?? 'other';
                        final description = act['description'] ?? '';
                        final timeStr = act['created_at'] != null 
                            ? DateFormat('HH:mm').format(DateTime.parse(act['created_at']).toLocal())
                            : '';
                        final lat = act['latitude'] ?? 0.0;
                        final lng = act['longitude'] ?? 0.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getActivityColor(type).withAlpha(38),
                              foregroundColor: _getActivityColor(type),
                              child: Icon(_getActivityIcon(type)),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getTypeLabel(type),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  timeStr,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
