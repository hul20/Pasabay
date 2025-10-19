import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/verification_request.dart';
import '../models/verification_status.dart';

/// Service for handling verification requests
class VerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit a new verification request
  Future<String?> submitVerificationRequest({
    required String travelerId,
    required String travelerName,
    required String travelerEmail,
    required Map<String, String> documents,
  }) async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .insert({
            'traveler_id': travelerId,
            'traveler_name': travelerName,
            'traveler_email': travelerEmail,
            'documents': documents,
            'status': VerificationStatus.PENDING.name,
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error submitting verification request: $e');
      return null;
    }
  }

  /// Get verification request by ID
  Future<VerificationRequest?> getVerificationRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .select()
          .eq('id', requestId)
          .single();

      return VerificationRequest.fromJson(response);
    } catch (e) {
      print('Error getting verification request: $e');
      return null;
    }
  }

  /// Get verification requests for a traveler
  Future<List<VerificationRequest>> getTravelerRequests(
    String travelerId,
  ) async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .select()
          .eq('traveler_id', travelerId)
          .order('submitted_at', ascending: false);

      return (response as List)
          .map((json) => VerificationRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting traveler requests: $e');
      return [];
    }
  }

  /// Get all pending verification requests (for verifiers)
  Future<List<VerificationRequest>> getPendingRequests() async {
    try {
      final response = await _supabase
          .from('verification_requests')
          .select()
          .eq('status', VerificationStatus.PENDING.name)
          .order('submitted_at', ascending: true);

      return (response as List)
          .map((json) => VerificationRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get all verification requests with optional status filter
  Future<List<VerificationRequest>> getAllRequests({
    VerificationStatus? status,
  }) async {
    try {
      var query = _supabase.from('verification_requests').select();

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('submitted_at', ascending: false);

      return (response as List)
          .map((json) => VerificationRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all requests: $e');
      return [];
    }
  }

  /// Assign request to verifier
  Future<bool> assignToVerifier(
    String requestId,
    String verifierId,
    String verifierName,
  ) async {
    try {
      await _supabase
          .from('verification_requests')
          .update({
            'verifier_id': verifierId,
            'verifier_name': verifierName,
            'status': VerificationStatus.UNDER_REVIEW.name,
          })
          .eq('id', requestId);
      return true;
    } catch (e) {
      print('Error assigning to verifier: $e');
      return false;
    }
  }

  /// Approve verification request
  Future<bool> approveRequest(
    String requestId,
    String verifierId,
    String? notes,
  ) async {
    try {
      await _supabase
          .from('verification_requests')
          .update({
            'status': VerificationStatus.APPROVED.name,
            'verifier_id': verifierId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'verifier_notes': notes,
          })
          .eq('id', requestId);

      // Update user verification status
      final request = await getVerificationRequest(requestId);
      if (request != null) {
        await _supabase
            .from('users')
            .update({
              'is_verified': true,
              'verified_at': DateTime.now().toIso8601String(),
            })
            .eq('id', request.travelerId);
      }

      return true;
    } catch (e) {
      print('Error approving request: $e');
      return false;
    }
  }

  /// Reject verification request
  Future<bool> rejectRequest(
    String requestId,
    String verifierId,
    String reason,
    String? notes,
  ) async {
    try {
      await _supabase
          .from('verification_requests')
          .update({
            'status': VerificationStatus.REJECTED.name,
            'verifier_id': verifierId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'rejection_reason': reason,
            'verifier_notes': notes,
          })
          .eq('id', requestId);
      return true;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }

  /// Listen to verification request updates
  Stream<List<VerificationRequest>> watchPendingRequests() {
    return _supabase
        .from('verification_requests')
        .stream(primaryKey: ['id'])
        .eq('status', VerificationStatus.PENDING.name)
        .order('submitted_at')
        .map(
          (data) =>
              data.map((json) => VerificationRequest.fromJson(json)).toList(),
        );
  }

  /// Get verification statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final allRequests = await getAllRequests();

      return {
        'total': allRequests.length,
        'pending': allRequests
            .where((r) => r.status == VerificationStatus.PENDING)
            .length,
        'under_review': allRequests
            .where((r) => r.status == VerificationStatus.UNDER_REVIEW)
            .length,
        'approved': allRequests
            .where((r) => r.status == VerificationStatus.APPROVED)
            .length,
        'rejected': allRequests
            .where((r) => r.status == VerificationStatus.REJECTED)
            .length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }
}
