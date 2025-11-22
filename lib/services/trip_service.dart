import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
import '../utils/supabase_service.dart';

/// Service class for managing trips in Supabase
class TripService {
  // Singleton pattern
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  SupabaseClient get _supabase => _supabaseService.client;

  /// Create a new trip
  Future<Trip> createTrip({
    required String departureLocation,
    double? departureLat,
    double? departureLng,
    required String destinationLocation,
    double? destinationLat,
    double? destinationLng,
    required DateTime departureDate,
    required String departureTime,
    String? estimatedArrivalTime,
    int availableCapacity = 5,
    double baseFee = 0.0,
    String? notes,
    String? routePolyline,
  }) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw 'User not authenticated';

      final now = DateTime.now();
      
      final tripData = {
        'traveler_id': user.id,
        'departure_location': departureLocation,
        'departure_lat': departureLat,
        'departure_lng': departureLng,
        'destination_location': destinationLocation,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
        'departure_date': departureDate.toIso8601String().split('T')[0],
        'departure_time': departureTime,
        'estimated_arrival_time': estimatedArrivalTime,
        'trip_status': 'Upcoming',
        'available_capacity': availableCapacity,
        'current_requests': 0,
        'base_fee': baseFee,
        'total_earnings': 0.0,
        'notes': notes,
        'route_polyline': routePolyline,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('trips')
          .insert(tripData)
          .select()
          .single();

      print('✅ Trip created successfully: ${response['id']}');
      return Trip.fromJson(response);
    } catch (e) {
      print('❌ Error creating trip: $e');
      throw 'Failed to create trip: $e';
    }
  }

  /// Get all trips for the current traveler
  Future<List<Trip>> getTravelerTrips() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw 'User not authenticated';

      final response = await _supabase
          .from('trips')
          .select()
          .eq('traveler_id', user.id)
          .order('departure_date', ascending: true)
          .order('departure_time', ascending: true);

      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching trips: $e');
      throw 'Failed to fetch trips: $e';
    }
  }

  /// Get upcoming trips for the current traveler
  Future<List<Trip>> getUpcomingTrips() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw 'User not authenticated';

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('trips')
          .select()
          .eq('traveler_id', user.id)
          .eq('trip_status', 'Upcoming')
          .gte('departure_date', today)
          .order('departure_date', ascending: true)
          .order('departure_time', ascending: true);

      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching upcoming trips: $e');
      return [];
    }
  }

  /// Get active trips (Upcoming and In Progress)
  Future<List<Trip>> getActiveTrips() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw 'User not authenticated';

      final response = await _supabase
          .from('trips')
          .select()
          .eq('traveler_id', user.id)
          .inFilter('trip_status', ['Upcoming', 'In Progress'])
          .order('departure_date', ascending: true);

      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching active trips: $e');
      return [];
    }
  }

  /// Get trip statistics for the current traveler
  Future<TripStats> getTripStats() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw 'User not authenticated';

      final response = await _supabase
          .rpc('get_trip_stats', params: {'_traveler_id': user.id});

      if (response == null) return TripStats.empty();
      
      return TripStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error fetching trip stats: $e');
      return TripStats.empty();
    }
  }

  /// Update trip details
  Future<Trip> updateTrip({
    required String tripId,
    String? departureLocation,
    double? departureLat,
    double? departureLng,
    String? destinationLocation,
    double? destinationLat,
    double? destinationLng,
    DateTime? departureDate,
    String? departureTime,
    String? estimatedArrivalTime,
    String? tripStatus,
    int? availableCapacity,
    int? currentRequests,
    double? baseFee,
    double? totalEarnings,
    String? notes,
    String? routePolyline,
  }) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw 'User not authenticated';

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (departureLocation != null) updateData['departure_location'] = departureLocation;
      if (departureLat != null) updateData['departure_lat'] = departureLat;
      if (departureLng != null) updateData['departure_lng'] = departureLng;
      if (destinationLocation != null) updateData['destination_location'] = destinationLocation;
      if (destinationLat != null) updateData['destination_lat'] = destinationLat;
      if (destinationLng != null) updateData['destination_lng'] = destinationLng;
      if (departureDate != null) updateData['departure_date'] = departureDate.toIso8601String().split('T')[0];
      if (departureTime != null) updateData['departure_time'] = departureTime;
      if (estimatedArrivalTime != null) updateData['estimated_arrival_time'] = estimatedArrivalTime;
      if (tripStatus != null) updateData['trip_status'] = tripStatus;
      if (availableCapacity != null) updateData['available_capacity'] = availableCapacity;
      if (currentRequests != null) updateData['current_requests'] = currentRequests;
      if (baseFee != null) updateData['base_fee'] = baseFee;
      if (totalEarnings != null) updateData['total_earnings'] = totalEarnings;
      if (notes != null) updateData['notes'] = notes;
      if (routePolyline != null) updateData['route_polyline'] = routePolyline;

      final response = await _supabase
          .from('trips')
          .update(updateData)
          .eq('id', tripId)
          .eq('traveler_id', user.id)
          .select()
          .single();

      print('✅ Trip updated successfully: $tripId');
      return Trip.fromJson(response);
    } catch (e) {
      print('❌ Error updating trip: $e');
      throw 'Failed to update trip: $e';
    }
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw 'User not authenticated';

      await _supabase
          .from('trips')
          .delete()
          .eq('id', tripId)
          .eq('traveler_id', user.id);

      print('✅ Trip deleted successfully: $tripId');
    } catch (e) {
      print('❌ Error deleting trip: $e');
      throw 'Failed to delete trip: $e';
    }
  }

  /// Cancel a trip (soft delete - changes status to Cancelled)
  Future<Trip> cancelTrip(String tripId) async {
    return await updateTrip(
      tripId: tripId,
      tripStatus: 'Cancelled',
    );
  }

  /// Start a trip (change status to In Progress)
  Future<Trip> startTrip(String tripId) async {
    return await updateTrip(
      tripId: tripId,
      tripStatus: 'In Progress',
    );
  }

  /// Complete a trip (change status to Completed)
  Future<Trip> completeTrip(String tripId) async {
    return await updateTrip(
      tripId: tripId,
      tripStatus: 'Completed',
    );
  }

  /// Search for available trips (for requesters)
  Future<List<Trip>> searchAvailableTrips({
    String? departureLocation,
    String? destinationLocation,
    DateTime? departureDate,
  }) async {
    try {
      var query = _supabase
          .from('trips')
          .select()
          .inFilter('trip_status', ['Upcoming', 'In Progress'])
          .lt('current_requests', 'available_capacity');

      if (departureLocation != null && departureLocation.isNotEmpty) {
        query = query.ilike('departure_location', '%$departureLocation%');
      }

      if (destinationLocation != null && destinationLocation.isNotEmpty) {
        query = query.ilike('destination_location', '%$destinationLocation%');
      }

      if (departureDate != null) {
        final dateStr = departureDate.toIso8601String().split('T')[0];
        query = query.gte('departure_date', dateStr);
      }

      final response = await query.order('departure_date', ascending: true);

      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error searching trips: $e');
      return [];
    }
  }

  /// Get a single trip by ID
  Future<Trip?> getTripById(String tripId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('id', tripId)
          .maybeSingle();

      if (response == null) return null;
      return Trip.fromJson(response);
    } catch (e) {
      print('❌ Error fetching trip: $e');
      return null;
    }
  }

  /// Stream of trips for real-time updates
  Stream<List<Trip>> streamTravelerTrips() {
    final user = _supabaseService.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('traveler_id', user.id)
        .order('departure_date', ascending: true)
        .map((data) => data.map((json) => Trip.fromJson(json)).toList());
  }
}

