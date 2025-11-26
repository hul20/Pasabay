import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationTrackingService {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _locationChannel;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;

  /// Check and request location permissions with detailed error messages
  Future<LocationPermissionResult> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult(
        granted: false,
        message:
            'Location services are disabled. Please enable location in your device settings.',
        shouldOpenSettings: true,
      );
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionResult(
          granted: false,
          message:
              'Location permission denied. This app needs location access to track deliveries.',
          shouldOpenSettings: false,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult(
        granted: false,
        message:
            'Location permission permanently denied. Please enable it in app settings.',
        shouldOpenSettings: true,
      );
    }

    // Check if we can get accurate location
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return LocationPermissionResult(
        granted: true,
        message: 'Location permission granted',
        shouldOpenSettings: false,
      );
    }

    return LocationPermissionResult(
      granted: false,
      message: 'Location permission not granted',
      shouldOpenSettings: false,
    );
  }

  /// Start tracking location for a service request (traveler)
  /// This will continuously track location while traveler is "On the Way"
  Future<void> startTracking(String requestId) async {
    if (_isTracking) {
      print('⚠️ Tracking already active');
      return;
    }

    // Check permissions first
    final permissionResult = await checkLocationPermission();
    if (!permissionResult.granted) {
      throw LocationPermissionException(
        permissionResult.message,
        permissionResult.shouldOpenSettings,
      );
    }

    _isTracking = true;
    print('📍 Starting location tracking for request: $requestId');

    // Start position stream with high accuracy
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update when moved 10 meters
            timeLimit: Duration(
              seconds: 5,
            ), // Get update at least every 5 seconds
          ),
        ).listen(
          (Position position) async {
            if (_isTracking) {
              await _updateLocation(requestId, position);
              print(
                '📍 Location updated: ${position.latitude}, ${position.longitude}',
              );
            }
          },
          onError: (error) {
            print('❌ Location stream error: $error');
            // Try to restart tracking if there's an error
            if (_isTracking) {
              print('🔄 Attempting to restart tracking...');
              stopTracking();
              Future.delayed(Duration(seconds: 2), () {
                if (!_isTracking) {
                  startTracking(requestId);
                }
              });
            }
          },
          cancelOnError: false,
        );

    // Get initial position immediately
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocation(requestId, initialPosition);
      print(
        '✅ Initial location set: ${initialPosition.latitude}, ${initialPosition.longitude}',
      );
    } catch (e) {
      print('⚠️ Could not get initial position: $e');
    }
  }

  /// Stop tracking location and clean up resources
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    print('🛑 Location tracking stopped');
  }

  /// Update location in database
  Future<void> _updateLocation(String requestId, Position position) async {
    try {
      await _supabase
          .from('service_requests')
          .update({
            'traveler_latitude': position.latitude,
            'traveler_longitude': position.longitude,
            'location_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Subscribe to location updates (requester)
  RealtimeChannel subscribeToLocation(
    String requestId,
    Function(double lat, double lng) onLocationUpdate,
  ) {
    _locationChannel = _supabase
        .channel('location:$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'service_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: requestId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data['traveler_latitude'] != null &&
                data['traveler_longitude'] != null) {
              onLocationUpdate(
                data['traveler_latitude'] as double,
                data['traveler_longitude'] as double,
              );
            }
          },
        )
        .subscribe();

    return _locationChannel!;
  }

  /// Unsubscribe from location updates
  void unsubscribeFromLocation() {
    if (_locationChannel != null) {
      _supabase.removeChannel(_locationChannel!);
      _locationChannel = null;
    }
  }

  /// Get current location of traveler from database
  Future<Map<String, double>?> getCurrentLocation(String requestId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .select('traveler_latitude, traveler_longitude, location_updated_at')
          .eq('id', requestId)
          .single();

      if (response['traveler_latitude'] != null &&
          response['traveler_longitude'] != null) {
        return {
          'latitude': response['traveler_latitude'] as double,
          'longitude': response['traveler_longitude'] as double,
        };
      }
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }
}

/// Result of location permission check
class LocationPermissionResult {
  final bool granted;
  final String message;
  final bool shouldOpenSettings;

  LocationPermissionResult({
    required this.granted,
    required this.message,
    required this.shouldOpenSettings,
  });
}

/// Exception for location permission issues
class LocationPermissionException implements Exception {
  final String message;
  final bool shouldOpenSettings;

  LocationPermissionException(this.message, this.shouldOpenSettings);

  @override
  String toString() => message;
}
