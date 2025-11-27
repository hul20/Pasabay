import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin, pi;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for calculating distances and pricing
class DistanceService {
  // Singleton pattern
  static final DistanceService _instance = DistanceService._internal();
  factory DistanceService() => _instance;
  DistanceService._internal();

  // Google Maps API Key
  static const String _apiKey = 'AIzaSyDa4-qOXBHMVcyCt9Wj7LldHQB6v_VlM5M';

  // Pricing constants - ₱1 per kilometer
  static const double _pricePerKm = 1.0;
  static const double _minimumCharge = 20.0;

  /// Calculate distance using Google Maps Distance Matrix API
  Future<DistanceResult> calculateDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final origin = '$originLat,$originLng';
      final destination = '$destLat,$destLng';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$origin'
        '&destinations=$destination'
        '&key=$_apiKey'
        '&units=metric',
      );

      print(
        '🌐 Calculating distance from ($originLat, $originLng) to ($destLat, $destLng)',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['rows'] != null &&
            data['rows'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];

          if (element['status'] == 'OK') {
            final distanceInMeters = element['distance']['value'] as int;
            final distanceInKm = distanceInMeters / 1000.0;
            final durationInSeconds = element['duration']['value'] as int;

            // Calculate price based on distance
            final calculatedPrice = _calculatePrice(distanceInKm);

            print(
              '✅ Distance: ${distanceInKm.toStringAsFixed(2)} km, Price: ₱${calculatedPrice.toStringAsFixed(2)}',
            );

            return DistanceResult(
              distanceInKm: distanceInKm,
              durationInMinutes: durationInSeconds / 60,
              price: calculatedPrice,
              success: true,
            );
          }
        }

        // If API fails, fall back to haversine formula
        print('⚠️ Distance Matrix API failed, using haversine formula');
        return _calculateDistanceHaversine(
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        );
      }

      // API call failed
      print('❌ Distance API failed with status: ${response.statusCode}');
      return _calculateDistanceHaversine(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
    } catch (e) {
      print('❌ Error calculating distance: $e');
      // Fall back to haversine formula
      return _calculateDistanceHaversine(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
    }
  }

  /// Calculate price based on distance
  double _calculatePrice(double distanceInKm) {
    final calculatedPrice = distanceInKm * _pricePerKm;
    // Ensure minimum charge
    return calculatedPrice < _minimumCharge ? _minimumCharge : calculatedPrice;
  }

  /// Fallback: Calculate distance using Haversine formula (as the crow flies)
  DistanceResult _calculateDistanceHaversine({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(destLat - originLat);
    final dLon = _degreesToRadians(destLng - originLng);

    final lat1 = _degreesToRadians(originLat);
    final lat2 = _degreesToRadians(destLat);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2));
    final c = 2 * asin(sqrt(a));
    final distanceInKm = earthRadiusKm * c;

    // Estimate duration (assuming 40 km/h average speed)
    final durationInMinutes = (distanceInKm / 40.0) * 60.0;

    // Calculate price
    final price = _calculatePrice(distanceInKm);

    print(
      '✅ Haversine distance: ${distanceInKm.toStringAsFixed(2)} km, Price: ₱${price.toStringAsFixed(2)}',
    );

    return DistanceResult(
      distanceInKm: distanceInKm,
      durationInMinutes: durationInMinutes,
      price: price,
      success: true,
      isEstimate: true,
    );
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  double sin(double radians) {
    return _sin(radians);
  }

  double _sin(double x) {
    // Taylor series approximation for sine
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  /// Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1.0) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceInKm.toStringAsFixed(2)} km';
  }

  /// Format duration for display
  String formatDuration(double durationInMinutes) {
    if (durationInMinutes < 60) {
      return '${durationInMinutes.toStringAsFixed(0)} min';
    }
    final hours = durationInMinutes ~/ 60;
    final mins = durationInMinutes % 60;
    return '${hours}h ${mins.toStringAsFixed(0)}m';
  }

  /// Format price for display
  String formatPrice(double price) {
    return '₱${price.toStringAsFixed(2)}';
  }

  /// Fetch route polyline from Google Directions API
  Future<List<LatLng>> getRoutePolyline({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final origin = '$originLat,$originLng';
      final destination = '$destLat,$destLng';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin'
        '&destination=$destination'
        '&key=$_apiKey'
        '&mode=driving',
      );

      print('🗺️ ====== DIRECTIONS API CALL ======');
      print('🗺️ Origin: $origin');
      print('🗺️ Destination: $destination');
      print('🗺️ URL: $url');

      final response = await http.get(url);
      print('📡 Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📡 API status: ${data['status']}');

        if (data['error_message'] != null) {
          print('❌ API error message: ${data['error_message']}');
        }

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          // Get the encoded polyline from the overview_polyline
          final encodedPolyline =
              data['routes'][0]['overview_polyline']['points'] as String;
          print('📍 Encoded polyline length: ${encodedPolyline.length} chars');

          // Decode the polyline
          final List<LatLng> points = _decodePolyline(encodedPolyline);
          print('✅ Decoded ${points.length} route points');
          print('🗺️ ====== END DIRECTIONS API ======');
          return points;
        } else if (data['status'] == 'REQUEST_DENIED') {
          print('❌ REQUEST_DENIED: ${data['error_message']}');
          print(
            '⚠️ Make sure Directions API is enabled in Google Cloud Console',
          );
          print(
            '⚠️ Also check API key restrictions (HTTP referrers, IP addresses)',
          );
        } else if (data['status'] == 'ZERO_RESULTS') {
          print('⚠️ ZERO_RESULTS: No route found between locations');
        } else {
          print('⚠️ Unexpected status: ${data['status']}');
          print('⚠️ Full response: ${response.body.substring(0, 500)}...');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }

      print('⚠️ Falling back to straight line');
      print('🗺️ ====== END DIRECTIONS API ======');
      return [LatLng(originLat, originLng), LatLng(destLat, destLng)];
    } catch (e, stackTrace) {
      print('❌ Exception in getRoutePolyline: $e');
      print('❌ Stack trace: $stackTrace');
      return [LatLng(originLat, originLng), LatLng(destLat, destLng)];
    }
  }

  /// Decode an encoded polyline string into a list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

/// Result of distance calculation
class DistanceResult {
  final double distanceInKm;
  final double durationInMinutes;
  final double price;
  final bool success;
  final bool isEstimate; // True if using haversine instead of Google API
  final String? errorMessage;

  DistanceResult({
    required this.distanceInKm,
    required this.durationInMinutes,
    required this.price,
    required this.success,
    this.isEstimate = false,
    this.errorMessage,
  });

  factory DistanceResult.error(String message) {
    return DistanceResult(
      distanceInKm: 0,
      durationInMinutes: 0,
      price: 0,
      success: false,
      errorMessage: message,
    );
  }
}
