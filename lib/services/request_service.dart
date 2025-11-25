import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request.dart';
import '../models/trip.dart';

class RequestService {
  final _supabase = Supabase.instance.client;

  // Search for available trips based on location
  Future<List<Trip>> searchAvailableTrips({
    required String departureLocation,
    required String destinationLocation,
    DateTime? travelDate,
  }) async {
    try {
      // Get all trips and filter in Dart
      final response = await _supabase.from('trips').select();

      final allTrips = (response as List)
          .map((trip) => Trip.fromJson(trip))
          .toList();

      print('🔍 Found ${allTrips.length} total trips');

      // Filter in Dart for active trips and matching criteria
      final filteredTrips = allTrips.where((trip) {
        // Check if trip is active (Upcoming or In Progress)
        bool isActive =
            trip.tripStatus == 'Upcoming' || trip.tripStatus == 'In Progress';

        // Check location match
        bool matchesDeparture = trip.departureLocation.toLowerCase().contains(
          departureLocation.toLowerCase(),
        );
        bool matchesDestination = trip.destinationLocation
            .toLowerCase()
            .contains(destinationLocation.toLowerCase());

        // Check date match
        bool matchesDate = true;
        if (travelDate != null) {
          final tripDate = trip.departureDate;
          matchesDate =
              tripDate.year == travelDate.year &&
              tripDate.month == travelDate.month &&
              tripDate.day == travelDate.day;
        }

        // Check if trip has available capacity
        bool hasCapacity = trip.currentRequests < trip.availableCapacity;

        return isActive &&
            matchesDeparture &&
            matchesDestination &&
            matchesDate &&
            hasCapacity;
      }).toList();

      print('✅ Filtered to ${filteredTrips.length} matching trips');
      return filteredTrips;
    } catch (e) {
      print('❌ Error searching trips: $e');
      return [];
    }
  }

  // Submit a Pabakal request
  Future<String?> submitPabakalRequest({
    required String travelerId,
    required String tripId,
    required String productName,
    required String storeName,
    required String storeLocation,
    required double productCost,
    required double serviceFee,
    String? notes,
    List<String>? photoUrls,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ User not authenticated');
        throw 'User not authenticated';
      }

      print('📤 Submitting Pabakal request...');
      print('   Requester: $userId');
      print('   Traveler: $travelerId');
      print('   Trip: $tripId');
      print('   Product: $productName');

      final response = await _supabase
          .from('service_requests')
          .insert({
            'requester_id': userId,
            'traveler_id': travelerId,
            'trip_id': tripId,
            'service_type': 'Pabakal',
            'product_name': productName,
            'store_name': storeName,
            'store_location': storeLocation,
            'product_cost': productCost,
            'service_fee': serviceFee,
            'total_amount': productCost + serviceFee,
            'notes': notes,
            'status': 'Pending',
            'photo_urls': photoUrls,
          })
          .select()
          .single();

      print('✅ Pabakal request submitted: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('❌ Error submitting Pabakal request: $e');
      rethrow;
    }
  }

  // Submit a Pasabay request
  Future<String?> submitPasabayRequest({
    required String travelerId,
    required String tripId,
    required String packageDescription,
    required String recipientName,
    required String recipientPhone,
    required String dropoffLocation,
    required double serviceFee,
    String? notes,
    List<String>? photoUrls,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ User not authenticated');
        throw 'User not authenticated';
      }

      print('📤 Submitting Pasabay request...');
      print('   Requester: $userId');
      print('   Traveler: $travelerId');
      print('   Trip: $tripId');
      print('   Recipient: $recipientName');
      print('   Phone: $recipientPhone');

      final response = await _supabase
          .from('service_requests')
          .insert({
            'requester_id': userId,
            'traveler_id': travelerId,
            'trip_id': tripId,
            'service_type': 'Pasabay',
            'package_description': packageDescription,
            'recipient_name': recipientName,
            'recipient_phone': recipientPhone,
            'dropoff_location': dropoffLocation,
            'service_fee': serviceFee,
            'total_amount': serviceFee,
            'notes': notes,
            'status': 'Pending',
            'photo_urls': photoUrls,
          })
          .select()
          .single();

      print('✅ Pasabay request submitted: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('❌ Error submitting Pasabay request: $e');
      rethrow;
    }
  }

  // Upload attachments to Supabase Storage
  Future<List<String>> uploadAttachments(
    String requestId,
    List<String> filePaths,
  ) async {
    List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < filePaths.length; i++) {
        final fileName = 'request_$requestId\_attachment_$i';
        final filePath = filePaths[i];

        // Note: For actual file upload, you'll need to use the proper file handling
        // This is a placeholder - you'll need to convert file path to bytes
        // await _supabase.storage.from('attachments').upload(fileName, File(filePath));

        final url = _supabase.storage
            .from('attachments')
            .getPublicUrl(fileName);

        uploadedUrls.add(url);
      }

      return uploadedUrls;
    } catch (e) {
      print('Error uploading attachments: $e');
      rethrow;
    }
  }

  // Accept a request (traveler side)
  Future<bool> acceptRequest(String requestId) async {
    try {
      await _supabase.rpc(
        'accept_service_request',
        params: {'request_id': requestId},
      );
      return true;
    } catch (e) {
      print('Error accepting request: $e');
      return false;
    }
  }

  // Reject a request (traveler side)
  Future<bool> rejectRequest(String requestId, [String? reason]) async {
    try {
      await _supabase.rpc(
        'reject_service_request',
        params: {
          'request_id': requestId,
          'reason': reason ?? 'Request declined',
        },
      );
      return true;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }

  // Get traveler's requests (for activity page)
  Future<List<ServiceRequest>> getTravelerRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('traveler_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((request) => ServiceRequest.fromJson(request))
          .toList();
    } catch (e) {
      print('Error fetching traveler requests: $e');
      return [];
    }
  }

  // Create a generic request (used by traveler_detail_page.dart)
  Future<bool> createRequest({
    required String travelerId,
    required String tripId,
    required String serviceType,
    String? productName,
    String? storeName,
    String? storeLocation,
    double? productCost,
    String? productDescription,
    String? packageDescription,
    String? recipientName,
    String? recipientPhone,
    String? pickupLocation,
    String? dropoffLocation,
    DateTime? pickupTime,
    required double serviceFee,
    String? notes,
    List<String>? photoUrls,
  }) async {
    try {
      String? requestId;

      if (serviceType == 'Pabakal') {
        requestId = await submitPabakalRequest(
          travelerId: travelerId,
          tripId: tripId,
          productName: productName ?? '',
          storeName: storeName ?? '',
          storeLocation: storeLocation ?? '',
          productCost: productCost ?? 0.0,
          serviceFee: serviceFee,
          notes: productDescription ?? notes,
          photoUrls: photoUrls,
        );
      } else {
        requestId = await submitPasabayRequest(
          travelerId: travelerId,
          tripId: tripId,
          packageDescription: packageDescription ?? '',
          recipientName: recipientName ?? '',
          recipientPhone: recipientPhone ?? '',
          dropoffLocation: dropoffLocation ?? '',
          serviceFee: serviceFee,
          notes: notes,
          photoUrls: photoUrls,
        );
      }

      return requestId != null;
    } catch (e) {
      print('Error creating request: $e');
      return false;
    }
  }

  // Get or create conversation (for request acceptance)
  Future<String?> getOrCreateConversation(String requestId) async {
    try {
      final response = await _supabase.rpc(
        'get_or_create_conversation',
        params: {'req_id': requestId},
      );

      return response as String?;
    } catch (e) {
      print('Error getting/creating conversation: $e');
      return null;
    }
  }

  // Cancel a request (requester side)
  Future<bool> cancelRequest(String requestId) async {
    try {
      await _supabase.rpc(
        'cancel_service_request',
        params: {'request_id': requestId},
      );
      return true;
    } catch (e) {
      print('Error cancelling request: $e');
      return false;
    }
  }

  // Get requester info
  Future<Map<String, dynamic>?> getRequesterInfo(String requesterId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('first_name, last_name, profile_image_url')
          .eq('id', requesterId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching requester info: $e');
      return null;
    }
  }

  // Get traveler info
  Future<Map<String, dynamic>?> getTravelerInfo(String travelerId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('first_name, last_name, profile_image_url')
          .eq('id', travelerId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching traveler info: $e');
      return null;
    }
  }

  // Get pending requests for a specific trip (traveler side)
  Future<List<ServiceRequest>> getPendingRequestsForTrip(String tripId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('trip_id', tripId)
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((request) => ServiceRequest.fromJson(request))
          .toList();
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  // Get ongoing (accepted) requests for a specific trip (traveler side)
  Future<List<ServiceRequest>> getOngoingRequestsForTrip(String tripId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('trip_id', tripId)
          .eq('status', 'Accepted')
          .order('created_at', ascending: false);

      return (response as List)
          .map((request) => ServiceRequest.fromJson(request))
          .toList();
    } catch (e) {
      print('Error fetching ongoing requests: $e');
      return [];
    }
  }

  // Get requester's requests (requester side)
  Future<List<ServiceRequest>> getRequesterRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((request) => ServiceRequest.fromJson(request))
          .toList();
    } catch (e) {
      print('Error fetching requester requests: $e');
      return [];
    }
  }

  // Get request by ID
  Future<ServiceRequest?> getRequestById(String requestId) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('id', requestId)
          .single();

      return ServiceRequest.fromJson(response);
    } catch (e) {
      print('Error fetching request by ID: $e');
      return null;
    }
  }
}
