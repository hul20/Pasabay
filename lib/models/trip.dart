/// Trip model representing a traveler's scheduled journey
class Trip {
  final String id;
  final String travelerId;

  // Location information
  final String departureLocation;
  final double? departureLat;
  final double? departureLng;
  final String destinationLocation;
  final double? destinationLat;
  final double? destinationLng;

  // Schedule information
  final DateTime departureDate;
  final String departureTime; // Format: HH:mm:ss
  final String? estimatedArrivalTime;

  // Trip details
  final String tripStatus; // Upcoming, In Progress, Completed, Cancelled
  final int availableCapacity;
  final int currentRequests;

  // Financial
  final double baseFee;
  final double totalEarnings;
  final double pasabayPrice; // Price traveler charges for Pasabay service
  final double pabakalPrice; // Price traveler charges for Pabakal service

  // Additional info
  final String? notes;
  final String? routePolyline;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.travelerId,
    required this.departureLocation,
    this.departureLat,
    this.departureLng,
    required this.destinationLocation,
    this.destinationLat,
    this.destinationLng,
    required this.departureDate,
    required this.departureTime,
    this.estimatedArrivalTime,
    this.tripStatus = 'Upcoming',
    this.availableCapacity = 5,
    this.currentRequests = 0,
    this.baseFee = 0.0,
    this.totalEarnings = 0.0,
    this.pasabayPrice = 50.0,
    this.pabakalPrice = 100.0,
    this.notes,
    this.routePolyline,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Trip from JSON (from Supabase)
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      travelerId: json['traveler_id'] as String,
      departureLocation: json['departure_location'] as String,
      departureLat: json['departure_lat'] != null
          ? (json['departure_lat'] as num).toDouble()
          : null,
      departureLng: json['departure_lng'] != null
          ? (json['departure_lng'] as num).toDouble()
          : null,
      destinationLocation: json['destination_location'] as String,
      destinationLat: json['destination_lat'] != null
          ? (json['destination_lat'] as num).toDouble()
          : null,
      destinationLng: json['destination_lng'] != null
          ? (json['destination_lng'] as num).toDouble()
          : null,
      departureDate: DateTime.parse(json['departure_date'] as String),
      departureTime: json['departure_time'] as String,
      estimatedArrivalTime: json['estimated_arrival_time'] as String?,
      tripStatus: json['trip_status'] as String? ?? 'Upcoming',
      availableCapacity: json['available_capacity'] as int? ?? 5,
      currentRequests: json['current_requests'] as int? ?? 0,
      baseFee: json['base_fee'] != null
          ? (json['base_fee'] as num).toDouble()
          : 0.0,
      totalEarnings: json['total_earnings'] != null
          ? (json['total_earnings'] as num).toDouble()
          : 0.0,
      pasabayPrice: json['pasabay_price'] != null
          ? (json['pasabay_price'] as num).toDouble()
          : 50.0,
      pabakalPrice: json['pabakal_price'] != null
          ? (json['pabakal_price'] as num).toDouble()
          : 100.0,
      notes: json['notes'] as String?,
      routePolyline: json['route_polyline'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Trip to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'traveler_id': travelerId,
      'departure_location': departureLocation,
      'departure_lat': departureLat,
      'departure_lng': departureLng,
      'destination_location': destinationLocation,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'departure_date': departureDate.toIso8601String().split(
        'T',
      )[0], // Date only
      'departure_time': departureTime,
      'estimated_arrival_time': estimatedArrivalTime,
      'trip_status': tripStatus,
      'available_capacity': availableCapacity,
      'current_requests': currentRequests,
      'base_fee': baseFee,
      'total_earnings': totalEarnings,
      'pasabay_price': pasabayPrice,
      'pabakal_price': pabakalPrice,
      'notes': notes,
      'route_polyline': routePolyline,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Trip copyWith({
    String? id,
    String? travelerId,
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
    double? pasabayPrice,
    double? pabakalPrice,
    String? notes,
    String? routePolyline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      travelerId: travelerId ?? this.travelerId,
      departureLocation: departureLocation ?? this.departureLocation,
      departureLat: departureLat ?? this.departureLat,
      departureLng: departureLng ?? this.departureLng,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      tripStatus: tripStatus ?? this.tripStatus,
      availableCapacity: availableCapacity ?? this.availableCapacity,
      currentRequests: currentRequests ?? this.currentRequests,
      baseFee: baseFee ?? this.baseFee,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pasabayPrice: pasabayPrice ?? this.pasabayPrice,
      pabakalPrice: pabakalPrice ?? this.pabakalPrice,
      notes: notes ?? this.notes,
      routePolyline: routePolyline ?? this.routePolyline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted departure date (e.g., "Nov 21, 2025")
  String get formattedDepartureDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[departureDate.month - 1]} ${departureDate.day}, ${departureDate.year}';
  }

  /// Get formatted departure time (e.g., "08:00 AM")
  String get formattedDepartureTime {
    final parts = departureTime.split(':');
    if (parts.length < 2) return departureTime;

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Check if trip is active (Upcoming or In Progress)
  bool get isActive => tripStatus == 'Upcoming' || tripStatus == 'In Progress';

  /// Check if trip can accept more requests
  bool get canAcceptRequests => currentRequests < availableCapacity && isActive;

  @override
  String toString() {
    return 'Trip(id: $id, from: $departureLocation, to: $destinationLocation, status: $tripStatus)';
  }
}

/// Trip statistics model
class TripStats {
  final int activeTrips;
  final int completedTrips;
  final int cancelledTrips;
  final double totalEarnings;
  final double currentMonthEarnings;

  TripStats({
    required this.activeTrips,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.totalEarnings,
    required this.currentMonthEarnings,
  });

  factory TripStats.fromJson(Map<String, dynamic> json) {
    return TripStats(
      activeTrips: json['active_trips'] as int? ?? 0,
      completedTrips: json['completed_trips'] as int? ?? 0,
      cancelledTrips: json['cancelled_trips'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      currentMonthEarnings:
          (json['current_month_earnings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory TripStats.empty() {
    return TripStats(
      activeTrips: 0,
      completedTrips: 0,
      cancelledTrips: 0,
      totalEarnings: 0.0,
      currentMonthEarnings: 0.0,
    );
  }
}
