/// Model for traveler statistics and profile data
class TravelerStatistics {
  final String travelerId;
  final int totalTrips;
  final int successfulTrips;
  final int cancelledTrips;
  final double averageRating;
  final int totalRatings;
  final int totalAcceptedRequests;
  final int fulfilledRequests;
  final int cancelledRequests;
  final double reliabilityRate;
  final int pabakalCompleted;
  final int pasabayCompleted;
  final int onTimeDeliveries;
  final int lateDeliveries;
  final int fragileItemDeliveries;
  final int fiveStarPabakalCount;
  final DateTime? lastCalculatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TravelerStatistics({
    required this.travelerId,
    this.totalTrips = 0,
    this.successfulTrips = 0,
    this.cancelledTrips = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalAcceptedRequests = 0,
    this.fulfilledRequests = 0,
    this.cancelledRequests = 0,
    this.reliabilityRate = 0.0,
    this.pabakalCompleted = 0,
    this.pasabayCompleted = 0,
    this.onTimeDeliveries = 0,
    this.lateDeliveries = 0,
    this.fragileItemDeliveries = 0,
    this.fiveStarPabakalCount = 0,
    this.lastCalculatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TravelerStatistics.fromJson(Map<String, dynamic> json) {
    return TravelerStatistics(
      travelerId: json['traveler_id'] as String,
      totalTrips: json['total_trips'] as int? ?? 0,
      successfulTrips: json['successful_trips'] as int? ?? 0,
      cancelledTrips: json['cancelled_trips'] as int? ?? 0,
      averageRating: _parseDecimal(json['average_rating']),
      totalRatings: json['total_ratings'] as int? ?? 0,
      totalAcceptedRequests: json['total_accepted_requests'] as int? ?? 0,
      fulfilledRequests: json['fulfilled_requests'] as int? ?? 0,
      cancelledRequests: json['cancelled_requests'] as int? ?? 0,
      reliabilityRate: _parseDecimal(json['reliability_rate']),
      pabakalCompleted: json['pabakal_completed'] as int? ?? 0,
      pasabayCompleted: json['pasabay_completed'] as int? ?? 0,
      onTimeDeliveries: json['on_time_deliveries'] as int? ?? 0,
      lateDeliveries: json['late_deliveries'] as int? ?? 0,
      fragileItemDeliveries: json['fragile_item_deliveries'] as int? ?? 0,
      fiveStarPabakalCount: json['five_star_pabakal_count'] as int? ?? 0,
      lastCalculatedAt: json['last_calculated_at'] != null
          ? DateTime.parse(json['last_calculated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'traveler_id': travelerId,
      'total_trips': totalTrips,
      'successful_trips': successfulTrips,
      'cancelled_trips': cancelledTrips,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'total_accepted_requests': totalAcceptedRequests,
      'fulfilled_requests': fulfilledRequests,
      'cancelled_requests': cancelledRequests,
      'reliability_rate': reliabilityRate,
      'pabakal_completed': pabakalCompleted,
      'pasabay_completed': pasabayCompleted,
      'on_time_deliveries': onTimeDeliveries,
      'late_deliveries': lateDeliveries,
      'fragile_item_deliveries': fragileItemDeliveries,
      'five_star_pabakal_count': fiveStarPabakalCount,
      'last_calculated_at': lastCalculatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted average rating (e.g., "4.9")
  String get formattedRating => averageRating.toStringAsFixed(1);

  /// Get reliability rate as percentage string (e.g., "100%")
  String get formattedReliabilityRate =>
      '${reliabilityRate.toStringAsFixed(0)}%';
}

/// Model for traveler badges
class TravelerBadge {
  final String id;
  final String travelerId;
  final BadgeType badgeType;
  final int badgeLevel;
  final String? routeDeparture;
  final String? routeDestination;
  final DateTime earnedAt;
  final DateTime createdAt;

  TravelerBadge({
    required this.id,
    required this.travelerId,
    required this.badgeType,
    this.badgeLevel = 1,
    this.routeDeparture,
    this.routeDestination,
    required this.earnedAt,
    required this.createdAt,
  });

  factory TravelerBadge.fromJson(Map<String, dynamic> json) {
    return TravelerBadge(
      id: json['id'] as String,
      travelerId: json['traveler_id'] as String,
      badgeType: _parseBadgeType(json['badge_type'] as String),
      badgeLevel: json['badge_level'] as int? ?? 1,
      routeDeparture: json['route_departure'] as String?,
      routeDestination: json['route_destination'] as String?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static BadgeType _parseBadgeType(String type) {
    switch (type) {
      case 'flash_traveler':
        return BadgeType.flashTraveler;
      case 'pasabuy_pro':
        return BadgeType.pasabuyPro;
      case 'route_master':
        return BadgeType.routeMaster;
      case 'gentle_handler':
        return BadgeType.gentleHandler;
      default:
        return BadgeType.flashTraveler;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'traveler_id': travelerId,
      'badge_type': badgeType.value,
      'badge_level': badgeLevel,
      'route_departure': routeDeparture,
      'route_destination': routeDestination,
      'earned_at': earnedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get badge display name
  String get displayName {
    switch (badgeType) {
      case BadgeType.flashTraveler:
        return '⚡ Flash Traveler';
      case BadgeType.pasabuyPro:
        return '🛍️ Pasabuy Pro';
      case BadgeType.routeMaster:
        return '🛣️ Route Master';
      case BadgeType.gentleHandler:
        return '📦 Gentle Handler';
    }
  }

  /// Get badge description
  String get description {
    switch (badgeType) {
      case BadgeType.flashTraveler:
        return 'You can count on me to be on time.';
      case BadgeType.pasabuyPro:
        return 'I know how to pick good produce/items and handle receipts correctly.';
      case BadgeType.routeMaster:
        if (routeDeparture != null && routeDestination != null) {
          return 'I know the $routeDeparture-$routeDestination route like the back of my hand.';
        }
        return 'I know this road like the back of my hand; I won\'t get lost.';
      case BadgeType.gentleHandler:
        return 'Your birthday cake is safe with me.';
    }
  }

  /// Get badge icon
  String get icon {
    switch (badgeType) {
      case BadgeType.flashTraveler:
        return '⚡';
      case BadgeType.pasabuyPro:
        return '🛍️';
      case BadgeType.routeMaster:
        return '🛣️';
      case BadgeType.gentleHandler:
        return '📦';
    }
  }
}

/// Enum for badge types
enum BadgeType {
  flashTraveler('flash_traveler'),
  pasabuyPro('pasabuy_pro'),
  routeMaster('route_master'),
  gentleHandler('gentle_handler');

  final String value;
  const BadgeType(this.value);
}

/// Model for route statistics
class RouteStatistic {
  final String id;
  final String travelerId;
  final String departureLocation;
  final String destinationLocation;
  final int tripCount;
  final DateTime firstTripAt;
  final DateTime lastTripAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RouteStatistic({
    required this.id,
    required this.travelerId,
    required this.departureLocation,
    required this.destinationLocation,
    required this.tripCount,
    required this.firstTripAt,
    required this.lastTripAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteStatistic.fromJson(Map<String, dynamic> json) {
    return RouteStatistic(
      id: json['id'] as String,
      travelerId: json['traveler_id'] as String,
      departureLocation: json['departure_location'] as String,
      destinationLocation: json['destination_location'] as String,
      tripCount: json['trip_count'] as int,
      firstTripAt: DateTime.parse(json['first_trip_at'] as String),
      lastTripAt: DateTime.parse(json['last_trip_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'traveler_id': travelerId,
      'departure_location': departureLocation,
      'destination_location': destinationLocation,
      'trip_count': tripCount,
      'first_trip_at': firstTripAt.toIso8601String(),
      'last_trip_at': lastTripAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted route string
  String get routeString => '$departureLocation → $destinationLocation';
}

/// Model for ratings
class TravelerRating {
  final String id;
  final String travelerId;
  final String requesterId;
  final String tripId;
  final String requestId;
  final double rating;
  final String? reviewText;
  final double? punctualityRating;
  final double? communicationRating;
  final double? itemConditionRating;
  final bool isFragileHandler;
  final bool isFastDelivery;
  final bool isGoodShopper;
  final DateTime createdAt;
  final DateTime updatedAt;

  TravelerRating({
    required this.id,
    required this.travelerId,
    required this.requesterId,
    required this.tripId,
    required this.requestId,
    required this.rating,
    this.reviewText,
    this.punctualityRating,
    this.communicationRating,
    this.itemConditionRating,
    this.isFragileHandler = false,
    this.isFastDelivery = false,
    this.isGoodShopper = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TravelerRating.fromJson(Map<String, dynamic> json) {
    return TravelerRating(
      id: json['id'] as String,
      travelerId: json['traveler_id'] as String,
      requesterId: json['requester_id'] as String,
      tripId: json['trip_id'] as String,
      requestId: json['request_id'] as String,
      rating: _parseDecimal(json['rating']),
      reviewText: json['review_text'] as String?,
      punctualityRating: json['punctuality_rating'] != null
          ? _parseDecimal(json['punctuality_rating'])
          : null,
      communicationRating: json['communication_rating'] != null
          ? _parseDecimal(json['communication_rating'])
          : null,
      itemConditionRating: json['item_condition_rating'] != null
          ? _parseDecimal(json['item_condition_rating'])
          : null,
      isFragileHandler: json['is_fragile_handler'] as bool? ?? false,
      isFastDelivery: json['is_fast_delivery'] as bool? ?? false,
      isGoodShopper: json['is_good_shopper'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'traveler_id': travelerId,
      'requester_id': requesterId,
      'trip_id': tripId,
      'request_id': requestId,
      'rating': rating,
      'review_text': reviewText,
      'punctuality_rating': punctualityRating,
      'communication_rating': communicationRating,
      'item_condition_rating': itemConditionRating,
      'is_fragile_handler': isFragileHandler,
      'is_fast_delivery': isFastDelivery,
      'is_good_shopper': isGoodShopper,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get star rating display (e.g., "4.5 ⭐")
  String get starDisplay => '${rating.toStringAsFixed(1)} ⭐';
}
