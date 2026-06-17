import 'storage_service.dart';

class LocalizationService {
  static String _currentLanguage = 'tr';

  static final Map<String, Map<String, String>> _translations = {
    'tr': {
      // Common
      'app_name': 'Ekibim Nerede',
      'ok': 'Tamam',
      'cancel': 'İptal',
      'save': 'Kaydet',
      'error': 'Hata',
      'success': 'Başarılı',
      'loading': 'Yükleniyor...',

      // Roles
      'role_admin': 'Sistem Yöneticisi (Admin)',
      'role_manager': 'Yönetici',
      'role_user': 'Saha Personeli',

      // Login / Register
      'login_title': 'Ekibim Nerede',
      'login_subtitle': 'Ekip yönetim ve konum izleme portalı',
      'email': 'E-posta',
      'email_validation': 'E-posta adresi girin.',
      'password': 'Şifre',
      'password_validation': 'Şifrenizi girin.',
      'login_btn': 'Giriş Yap',
      'login_failed': 'Giriş başarısız. Lütfen e-posta ve şifrenizi kontrol edin.',
      'no_account': 'Hesabınız yok mu? Şimdi Kayıt Olun',
      'register_title': 'Kayıt Ol',
      'register_subtitle': 'Hesabınızı oluşturup sisteme katılın',
      'name': 'Ad Soyad',
      'name_validation': 'Ad soyad girin.',
      'confirm_password': 'Şifre Tekrarı',
      'confirm_password_validation': 'Şifrenizi tekrar girin.',
      'passwords_dont_match': 'Şifreler eşleşmiyor.',
      'register_btn': 'Kayıt Ol',
      'register_success': 'Kayıt başarılı! Giriş ekranına yönlendiriliyorsunuz.',
      'register_failed': 'Kayıt başarısız.',
      'has_account': 'Zaten hesabınız var mı? Giriş Yapın',

      // Dashboard
      'tab_shift': 'Mesai',
      'tab_tasks': 'Görevler',
      'tab_activity': 'Aktivite',
      'tab_leave': 'İzin',
      'dashboard_title': 'Saha Çalışanı Paneli',
      'welcome': 'Hoş Geldiniz',
      'role': 'Rol',
      'logout': 'Çıkış Yap',
      'language': 'Dil',
      'change_language': 'Dili Değiştir',
      'manager_actions': 'Yönetici İşlemleri',
      'new_task': 'Yeni Görev Ata',
      'new_task_subtitle': 'Harita üzerinden sahaya yeni görev ekle',
      'track_teams': 'Saha Ekiplerini İzle',
      'track_teams_subtitle': 'Canlı konum haritasını görüntüle',
      'worker_actions': 'Saha İşlemleri',
      'on_leave_today': 'Bugün İzinlisiniz',
      'leave_kvkk_warning': 'KVKK uyumluluğu nedeniyle izin günlerinde konum takibi yapılamaz ve mesai başlatılamaz.',
      'shift_clock': 'Mesai Giriş/Çıkış',
      'shift_clock_subtitle': 'QR kod ile mesai başlat veya bitir',
      'location_sharing_control': 'Konum Paylaşımı Kontrolü',
      'location_sharing_leave': 'İzinli günlerde takip kapalıdır',
      'location_sharing_active': 'Konum paylaşımı AKTİF',
      'location_sharing_inactive': 'Konum paylaşımı KAPALI',
      'log_activity': 'Aktivite Gir',
      'log_activity_subtitle': 'Günlük saha aktivitelerini kaydet',
      'leave_requests': 'İzin Talepleri',
      'leave_requests_subtitle': 'İzin isteklerini oluştur ve takip et',
      'my_tasks': 'Bana Atanan Görevler',
      'my_tasks_subtitle': 'Aktif görev listesini ve detaylarını gör',
      'security_session': 'Güvenlik ve Oturum',
      'active_session_token': 'Aktif Oturum Tokeni (JWT)',
      'no_token': 'Token yok',
      'rbac_active': 'Rol Tabanlı Erişim Koruma Aktif',

      // Shift
      'shift_status': 'Mesai Durumu',
      'not_started': 'Başlamadı',
      'active': 'Aktif',
      'shift_start_hint': 'Mesainizi başlatmak için QR kod okutmalısınız.',
      'scan_qr': 'QR KOD OKUT',
      'shift_started_at': 'Mesai Başlangıcı',
      'end_shift': 'MESAİYİ BİTİR',
      'clock_in_success': 'Mesai başarıyla başlatıldı.',
      'clock_out_success': 'Mesai başarıyla sonlandırıldı.',
      'location_error': 'Konum bilgisi alınamadı.',
      'sync_warning': 'İnternet bağlantısı yok. Konum yerel olarak kaydedildi, daha sonra eşitlenecek.',
      'kvkk_warning': 'İzinli olduğunuz günlerde konum takibi yapılmayacaktır.',

      // Tasks
      'tasks_title': 'Görevlerim',
      'no_tasks': 'Atanmış görev bulunmuyor.',
      'due_date': 'Bitiş Tarihi',
      'status_todo': 'Yapılacak',
      'status_in_progress': 'Yapılıyor',
      'status_done': 'Tamamlandı',
      'update_status': 'Durum Güncelle',
      'task_detail': 'Görev Detayı',

      // Activity
      'activities_title': 'Günlük Aktivitelerim',
      'new_activity': 'Yeni Aktivite Girişi',
      'activity_type': 'Aktivite Türü',
      'select_type': 'Tür Seçin',
      'activity_desc': 'Açıklama / Detay',
      'activity_desc_hint': 'Yapılan işin detayını girin...',
      'save_activity': 'Aktiviteyi Kaydet',
      'activity_saved': 'Aktivite başarıyla kaydedildi.',
      'no_description_validation': 'Lütfen açıklama girin.',
      'customer_visit': 'Müşteri Ziyareti',
      'assembly': 'Montaj / Kurulum',
      'break': 'Mola',
      'maintenance': 'Bakım / Onarım',
      'journey': 'Yolculuk',
      'other': 'Diğer',

      // Leave
      'leaves_title': 'İzin Taleplerim',
      'new_leave': 'Yeni İzin Talebi',
      'leave_type': 'İzin Türü',
      'leave_desc': 'Açıklama / Gerekçe',
      'start_date': 'Başlangıç Tarihi',
      'end_date': 'Bitiş Tarihi',
      'status': 'Durum',
      'status_pending': 'Onay Bekliyor',
      'status_approved': 'Onaylandı',
      'status_rejected': 'Reddedildi',
      'submit_request': 'Talebi Gönder',
      'leave_request_submitted': 'İzin talebi başarıyla iletildi.',
      'date_validation': 'Başlangıç tarihi bitiş tarihinden sonra olamaz.',
      'annual': 'Yıllık İzin',
      'sick': 'Sağlık / Rapor',
      'unpaid': 'Ücretsiz İzin',
    },
    'en': {
      // Common
      'app_name': 'My Team Tracker',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',

      // Roles
      'role_admin': 'System Administrator (Admin)',
      'role_manager': 'Manager',
      'role_user': 'Field Worker',

      // Login / Register
      'login_title': 'My Team Tracker',
      'login_subtitle': 'Team management and location tracking portal',
      'email': 'Email',
      'email_validation': 'Please enter an email address.',
      'password': 'Password',
      'password_validation': 'Please enter your password.',
      'login_btn': 'Log In',
      'login_failed': 'Login failed. Please check your email and password.',
      'no_account': "Don't have an account? Sign Up Now",
      'register_title': 'Register',
      'register_subtitle': 'Create your account and join the system',
      'name': 'Full Name',
      'name_validation': 'Please enter your name.',
      'confirm_password': 'Confirm Password',
      'confirm_password_validation': 'Please confirm your password.',
      'passwords_dont_match': 'Passwords do not match.',
      'register_btn': 'Register',
      'register_success': 'Registration successful! Redirecting to login.',
      'register_failed': 'Registration failed.',
      'has_account': 'Already have an account? Log In',

      // Dashboard
      'tab_shift': 'Shift',
      'tab_tasks': 'Tasks',
      'tab_activity': 'Activity',
      'tab_leave': 'Leave',
      'dashboard_title': 'Field Employee Panel',
      'welcome': 'Welcome',
      'role': 'Role',
      'logout': 'Log Out',
      'language': 'Language',
      'change_language': 'Change Language',
      'manager_actions': 'Manager Actions',
      'new_task': 'Assign New Task',
      'new_task_subtitle': 'Click a point on the map to define the task',
      'track_teams': 'Track Teams',
      'track_teams_subtitle': 'View live location tracking map',
      'worker_actions': 'Workforce Actions',
      'on_leave_today': 'You are on leave today',
      'leave_kvkk_warning': 'Due to KVKK compliance, location tracking is disabled and shifts cannot be started on leave days.',
      'shift_clock': 'Shift Clock-in/out',
      'shift_clock_subtitle': 'Clock in (via QR) or clock out from shift',
      'location_sharing_control': 'Location Sharing Control',
      'location_sharing_leave': 'Tracking offline on leave days',
      'location_sharing_active': 'Location sharing ACTIVE',
      'location_sharing_inactive': 'Location sharing OFFLINE',
      'log_activity': 'Log Activity',
      'log_activity_subtitle': 'Record daily field activities',
      'leave_requests': 'Leave Requests',
      'leave_requests_subtitle': 'Create and track leave applications',
      'my_tasks': 'My Assigned Tasks',
      'my_tasks_subtitle': 'View active tasks and details',
      'security_session': 'Security & Session',
      'active_session_token': 'Active Session Token (JWT)',
      'no_token': 'No token',
      'rbac_active': 'Role-Based Access Control Active',

      // Shift
      'shift_status': 'Shift Status',
      'not_started': 'Not Started',
      'active': 'Active',
      'shift_start_hint': 'You must scan a QR code to start your shift.',
      'scan_qr': 'SCAN QR CODE',
      'shift_started_at': 'Shift Started At',
      'end_shift': 'END SHIFT',
      'clock_in_success': 'Shift successfully started.',
      'clock_out_success': 'Shift successfully ended.',
      'location_error': 'Could not retrieve location.',
      'sync_warning': 'No internet connection. Location saved locally, will sync later.',
      'kvkk_warning': 'Location tracking will not be active on your days off.',

      // Tasks
      'tasks_title': 'My Tasks',
      'no_tasks': 'No assigned tasks found.',
      'due_date': 'Due Date',
      'status_todo': 'Todo',
      'status_in_progress': 'In Progress',
      'status_done': 'Completed',
      'update_status': 'Update Status',
      'task_detail': 'Task Detail',

      // Activity
      'activities_title': 'My Daily Activities',
      'new_activity': 'New Activity Entry',
      'activity_type': 'Activity Type',
      'select_type': 'Select Type',
      'activity_desc': 'Description / Details',
      'activity_desc_hint': 'Enter details of the work done...',
      'save_activity': 'Save Activity',
      'activity_saved': 'Activity successfully saved.',
      'no_description_validation': 'Please enter a description.',
      'customer_visit': 'Customer Visit',
      'assembly': 'Assembly / Installation',
      'break': 'Break',
      'maintenance': 'Maintenance / Repair',
      'journey': 'Journey / Travel',
      'other': 'Other',

      // Leave
      'leaves_title': 'My Leave Requests',
      'new_leave': 'New Leave Request',
      'leave_type': 'Leave Type',
      'leave_desc': 'Description / Reason',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'status': 'Status',
      'status_pending': 'Pending Approval',
      'status_approved': 'Approved',
      'status_rejected': 'Rejected',
      'submit_request': 'Submit Request',
      'leave_request_submitted': 'Leave request successfully submitted.',
      'date_validation': 'Start date cannot be after end date.',
      'annual': 'Annual Leave',
      'sick': 'Sick Leave',
      'unpaid': 'Unpaid Leave',
    }
  };

  static String get currentLanguage => _currentLanguage;

  static final Map<String, String> _locales = {
    'tr': 'Türkçe (TR)',
    'en': 'English (EN)'
  };

  static Map<String, String> get locales => _locales;

  static final _listeners = <void Function()>[];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Future<void> init() async {
    final lang = await StorageService().getLanguage();
    _currentLanguage = lang;
  }

  static Future<void> setLanguage(String lang) async {
    _currentLanguage = lang;
    await StorageService().saveLanguage(lang);
    _notifyListeners();
  }

  static String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }
}

String t(String key) => LocalizationService.translate(key);
