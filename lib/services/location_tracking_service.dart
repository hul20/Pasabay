import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationTrackingService {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _locationChannel;
  bool _isTracking = false;

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start tracking location for a service request (traveler)
  Future<void> startTracking(String requestId) async {
    if (_isTracking) return;

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    _isTracking = true;

    // Update location every 10 seconds
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      ),
    ).listen((Position position) async {
      if (_isTracking) {
        await _updateLocation(requestId, position);
      }
    });
  }

  /// Stop tracking location
  void stopTracking() {
    _isTracking = false;
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

  /// Get current location of traveler
  Future<Map<String, double>?> getCurrentLocation(String requestId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .select('traveler_latitude, traveler_longitude')
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
