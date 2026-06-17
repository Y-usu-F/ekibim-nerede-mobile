import 'dart:async';
import 'package:location/location.dart';
import 'api_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  LocationService._internal();

  final Location _location = Location();
  StreamSubscription<LocationData>? _subscription;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Requests location services and permissions.
  Future<bool> requestPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    return true;
  }

  /// Starts periodic tracking and sends coordinates to the REST API.
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    bool hasPermission = await requestPermissions();
    if (!hasPermission) return false;

    try {
      // Set update interval to 60 seconds and distance threshold to 10 meters
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 60000,
        distanceFilter: 10.0,
      );

      // Attempt to enable background mode execution
      try {
        await _location.enableBackgroundMode(enable: true);
      } catch (e) {
        print("Background mode error (handled): $e");
      }

      _subscription = _location.onLocationChanged.listen((LocationData data) async {
        if (data.latitude != null && data.longitude != null) {
          try {
            await ApiService().saveLocation(data.latitude!, data.longitude!);
            print("Dynamic Location Uploaded: ${data.latitude}, ${data.longitude}");
          } catch (e) {
            print("API Error uploading coordinates: $e");
          }
        }
      });

      _isTracking = true;
      return true;
    } catch (e) {
      print("Failed to start tracking subscription: $e");
      return false;
    }
  }

  /// Stops tracking updates and releases resources.
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _isTracking = false;
    try {
      _location.enableBackgroundMode(enable: false);
    } catch (_) {}
  }
}
