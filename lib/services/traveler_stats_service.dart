import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/traveler_statistics.dart';

/// Service for managing traveler ratings, statistics, and badges
class TravelerStatsService {
  final _supabase = Supabase.instance.client;

  // =====================================================
  // TRAVELER STATISTICS
  // =====================================================

  /// Get traveler statistics for a specific user
  Future<TravelerStatistics?> getTravelerStatistics(String travelerId) async {
    try {
      final response = await _supabase
          .from('traveler_statistics')
          .select()
          .eq('traveler_id', travelerId)
          .maybeSingle();

      if (response == null) {
        print('⚠️ No statistics found for traveler: $travelerId');
        return null;
      }

      return TravelerStatistics.fromJson(response);
    } catch (e) {
      print('❌ Error fetching traveler statistics: $e');
      return null;
    }
  }

  /// Get current user's statistics (must be logged in)
  Future<TravelerStatistics?> getMyStatistics() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user logged in');
        return null;
      }

      return await getTravelerStatistics(userId);
    } catch (e) {
      print('❌ Error fetching my statistics: $e');
      return null;
    }
  }

  // =====================================================
  // TRAVELER BADGES
  // =====================================================

  /// Get badges for a specific traveler
  Future<List<TravelerBadge>> getTravelerBadges(String travelerId) async {
    try {
      final response = await _supabase
          .from('traveler_badges')
          .select()
          .eq('traveler_id', travelerId)
          .order('earned_at', ascending: false);

      return (response as List)
          .map((json) => TravelerBadge.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching traveler badges: $e');
      return [];
    }
  }

  /// Get current user's badges
  Future<List<TravelerBadge>> getMyBadges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user logged in');
        return [];
      }

      return await getTravelerBadges(userId);
    } catch (e) {
      print('❌ Error fetching my badges: $e');
      return [];
    }
  }

  // =====================================================
  // ROUTE STATISTICS
  // =====================================================

  /// Get top routes for a traveler
  Future<List<RouteStatistic>> getTravelerTopRoutes(
    String travelerId, {
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('route_statistics')
          .select()
          .eq('traveler_id', travelerId)
          .order('trip_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => RouteStatistic.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching top routes: $e');
      return [];
    }
  }

  /// Get current user's top routes
  Future<List<RouteStatistic>> getMyTopRoutes({int limit = 5}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user logged in');
        return [];
      }

      return await getTravelerTopRoutes(userId, limit: limit);
    } catch (e) {
      print('❌ Error fetching my top routes: $e');
      return [];
    }
  }

  // =====================================================
  // RATINGS
  // =====================================================

  /// Get ratings for a specific traveler
  Future<List<TravelerRating>> getTravelerRatings(
    String travelerId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select()
          .eq('traveler_id', travelerId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TravelerRating.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching traveler ratings: $e');
      return [];
    }
  }

  /// Get current user's ratings (as traveler)
  Future<List<TravelerRating>> getMyRatings({int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user logged in');
        return [];
      }

      return await getTravelerRatings(userId, limit: limit);
    } catch (e) {
      print('❌ Error fetching my ratings: $e');
      return [];
    }
  }

  /// Submit a rating (requester rates traveler after completed request)
  Future<bool> submitRating({
    required String travelerId,
    required String tripId,
    required String requestId,
    required double rating,
    String? reviewText,
    double? punctualityRating,
    double? communicationRating,
    double? itemConditionRating,
    bool isFragileHandler = false,
    bool isFastDelivery = false,
    bool isGoodShopper = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user logged in');
        throw 'User not authenticated';
      }

      // Validate rating range
      if (rating < 1.0 || rating > 5.0) {
        throw 'Rating must be between 1.0 and 5.0';
      }

      await _supabase.from('ratings').insert({
        'traveler_id': travelerId,
        'requester_id': userId,
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
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Rating submitted successfully');
      return true;
    } catch (e) {
      print('❌ Error submitting rating: $e');
      return false;
    }
  }

  /// Check if user has already rated a request
  Future<bool> hasRatedRequest(String requestId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('ratings')
          .select('id')
          .eq('request_id', requestId)
          .eq('requester_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error checking if request is rated: $e');
      return false;
    }
  }

  // =====================================================
  // COMPLETE PROFILE DATA
  // =====================================================

  /// Get complete traveler profile (statistics + badges + top routes)
  Future<Map<String, dynamic>> getCompleteProfile(String travelerId) async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        getTravelerStatistics(travelerId),
        getTravelerBadges(travelerId),
        getTravelerTopRoutes(travelerId, limit: 5),
        getTravelerRatings(travelerId, limit: 10),
      ]);

      return {
        'statistics': results[0] as TravelerStatistics?,
        'badges': results[1] as List<TravelerBadge>,
        'top_routes': results[2] as List<RouteStatistic>,
        'recent_ratings': results[3] as List<TravelerRating>,
      };
    } catch (e) {
      print('❌ Error fetching complete profile: $e');
      return {
        'statistics': null,
        'badges': <TravelerBadge>[],
        'top_routes': <RouteStatistic>[],
        'recent_ratings': <TravelerRating>[],
      };
    }
  }

  /// Get my complete profile
  Future<Map<String, dynamic>> getMyCompleteProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw 'No user logged in';
      }

      return await getCompleteProfile(userId);
    } catch (e) {
      print('❌ Error fetching my complete profile: $e');
      return {
        'statistics': null,
        'badges': <TravelerBadge>[],
        'top_routes': <RouteStatistic>[],
        'recent_ratings': <TravelerRating>[],
      };
    }
  }

  // =====================================================
  // REAL-TIME SUBSCRIPTIONS
  // =====================================================

  /// Subscribe to statistics updates for current user
  RealtimeChannel subscribeToMyStatistics(
    Function(TravelerStatistics) onUpdate,
  ) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw 'No user logged in';
    }

    final channel = _supabase
        .channel('statistics:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'traveler_statistics',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'traveler_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final stats = TravelerStatistics.fromJson(payload.newRecord);
              onUpdate(stats);
            } catch (e) {
              print('❌ Error processing statistics update: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to badge updates for current user
  RealtimeChannel subscribeToMyBadges(Function(TravelerBadge) onNewBadge) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw 'No user logged in';
    }

    final channel = _supabase
        .channel('badges:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'traveler_badges',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'traveler_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final badge = TravelerBadge.fromJson(payload.newRecord);
              onNewBadge(badge);
            } catch (e) {
              print('❌ Error processing badge update: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from a channel
  void unsubscribe(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }
}
