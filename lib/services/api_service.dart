import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final _storage = StorageService();

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://api.ekibimnerede.srvpanel.benliyusuf.com.tr/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor wrapper to attach JWT authorization header automatically
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Expired or bad token, force clear authentication details
            await _storage.clearAuth();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// REST API: POST /login
  Future<Response> login(String email, String password) async {
    return await dio.post('login', data: {
      'email': email,
      'password': password,
    });
  }

  /// REST API: POST /register
  Future<Response> register(String name, String email, String password) async {
    return await dio.post('register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  /// REST API: POST /api/locations
  Future<Response> saveLocation(double latitude, double longitude) async {
    return await dio.post('api/locations', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// REST API: GET /api/shifts/status
  Future<Response> getShiftStatus() async {
    return await dio.get('api/shifts/status');
  }

  /// REST API: POST /api/shifts/clock-in
  Future<Response> clockIn(String qrCodeData, double latitude, double longitude) async {
    return await dio.post('api/shifts/clock-in', data: {
      'qr_code_data': qrCodeData,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// REST API: POST /api/shifts/clock-out
  Future<Response> clockOut(double latitude, double longitude) async {
    return await dio.post('api/shifts/clock-out', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// REST API: GET /api/tasks
  Future<Response> getTasks() async {
    return await dio.get('api/tasks');
  }

  /// REST API: PUT /api/tasks/:id/status
  Future<Response> updateTaskStatus(int taskId, String status) async {
    return await dio.put('api/tasks/$taskId/status', data: {
      'status': status,
    });
  }

  /// REST API: POST /api/locations/bulk
  Future<Response> saveLocationBulk(List<Map<String, dynamic>> locations) async {
    return await dio.post('api/locations/bulk', data: locations);
  }

  /// REST API: POST /api/leaves
  Future<Response> requestLeave({
    required String startDate,
    required String endDate,
    required String type,
    String? description,
  }) async {
    return await dio.post('api/leaves', data: {
      'start_date': startDate,
      'end_date': endDate,
      'type': type,
      'description': description ?? '',
    });
  }

  /// REST API: GET /api/leaves
  Future<Response> getMyLeaves() async {
    return await dio.get('api/leaves');
  }

  /// REST API: POST /api/activities
  Future<Response> createActivity({
    required String type,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    return await dio.post('api/activities', data: {
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// REST API: GET /api/activities
  Future<Response> getMyActivities() async {
    return await dio.get('api/activities');
  }
}
