import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _apiService = ApiService();
  bool _loading = true;
  List<dynamic> _leaves = [];
  String? _error;

  // Form controllers and state
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'annual';
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  final List<String> _types = [
    'annual',
    'sick',
    'unpaid',
    'other',
  ];

  String _getTypeLabel(String type) {
    switch (type) {
      case 'annual':
        return t('annual');
      case 'sick':
        return t('sick');
      case 'unpaid':
        return t('unpaid');
      case 'other':
      default:
        return t('other');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaves() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getMyLeaves();
      if (response.data != null && response.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _leaves = response.data['data'] ?? [];
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = LocalizationService.currentLanguage == 'en' ? 'Could not load leave requests.' : 'İzin talepleri yüklenemedi.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = LocalizationService.currentLanguage == 'en' ? 'Connection error: Could not fetch leave request list.' : 'Bağlantı hatası: İzin listesi alınamadı.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationService.currentLanguage == 'en' ? 'Please select start and end dates.' : 'Lütfen başlangıç ve bitiş tarihlerini seçin.')),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('date_validation'))),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDateStr = dateFormat.format(_startDate!);
    final endDateStr = dateFormat.format(_endDate!);

    try {
      final response = await _apiService.requestLeave(
        startDate: startDateStr,
        endDate: endDateStr,
        type: _selectedType,
        description: _descriptionController.text,
      );

      if (response.data != null && response.data['status'] == 'success') {
        // Clear form
        setState(() {
          _startDate = null;
          _endDate = null;
          _selectedType = 'annual';
          _descriptionController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('leave_request_submitted')),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchLeaves();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService.currentLanguage == 'en' ? 'Error: Could not create leave request' : 'Hata: İzin talebi oluşturulamadı'} ($e)'),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return t('status_approved');
      case 'rejected':
        return t('status_rejected');
      case 'pending':
      default:
        return t('status_pending');
    }
  }

  void _showNewRequestDialog() {
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
                            t('new_leave'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date selectors
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(_startDate == null
                                  ? (LocalizationService.currentLanguage == 'en' ? 'Select Start' : 'Başlangıç Seç')
                                  : DateFormat('dd.MM.yyyy').format(_startDate!)),
                              onPressed: () async {
                                await _selectDate(context, true);
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(_endDate == null
                                  ? (LocalizationService.currentLanguage == 'en' ? 'Select End' : 'Bitiş Seç')
                                  : DateFormat('dd.MM.yyyy').format(_endDate!)),
                              onPressed: () async {
                                await _selectDate(context, false);
                                setModalState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Type dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: t('leave_type'),
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
                          labelText: '${t('leave_desc')} (${LocalizationService.currentLanguage == 'en' ? 'Optional' : 'İsteğe Bağlı'})',
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _submitLeaveRequest();
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const CircularProgressIndicator()
                            : Text(t('submit_request'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('leaves_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeaves,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewRequestDialog,
        icon: const Icon(Icons.add),
        label: Text(LocalizationService.currentLanguage == 'en' ? 'New Request' : 'Yeni Talep'),
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
                          onPressed: _fetchLeaves,
                          child: Text(LocalizationService.currentLanguage == 'en' ? 'Try Again' : 'Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : _leaves.isEmpty
                  ? Center(
                      child: Text(
                        LocalizationService.currentLanguage == 'en' ? 'You do not have any leave requests yet.' : 'Henüz bir izin talebiniz bulunmamaktadır.',
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
                      itemCount: _leaves.length,
                      itemBuilder: (context, index) {
                        final leave = _leaves[index];
                        final status = leave['status'] ?? 'pending';
                        final type = leave['type'] ?? 'other';
                        final description = leave['description'] ?? '';
                        final rejectReason = leave['reject_reason'] ?? '';

                        final startStr = leave['start_date'] != null 
                            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(leave['start_date']))
                            : '';
                        final endStr = leave['end_date'] != null 
                            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(leave['end_date']))
                            : '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getTypeLabel(type),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$startStr - $endStr',
                                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                if (description.toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    description,
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                ],
                                if (status == 'rejected' && rejectReason.toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizationService.currentLanguage == 'en' ? 'Rejection Reason:' : 'Red Gerekçesi:',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          rejectReason,
                                          style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
