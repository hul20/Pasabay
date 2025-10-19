import 'verification_status.dart';

/// Represents a verification request from a traveler
class VerificationRequest {
  final String id;
  final String travelerId;
  final String travelerName;
  final String travelerEmail;
  final Map<String, String> documents;
  final VerificationStatus status;
  final String? verifierId;
  final String? verifierName;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? verifierNotes;

  VerificationRequest({
    required this.id,
    required this.travelerId,
    required this.travelerName,
    required this.travelerEmail,
    required this.documents,
    required this.status,
    this.verifierId,
    this.verifierName,
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.verifierNotes,
  });

  /// Create from Supabase JSON
  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'] as String,
      travelerId: json['traveler_id'] as String,
      travelerName: json['traveler_name'] as String? ?? 'Unknown',
      travelerEmail: json['traveler_email'] as String? ?? '',
      documents: Map<String, String>.from(json['documents'] as Map? ?? {}),
      status: VerificationStatus.fromString(
        json['status'] as String? ?? 'PENDING',
      ),
      verifierId: json['verifier_id'] as String?,
      verifierName: json['verifier_name'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      verifierNotes: json['verifier_notes'] as String?,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'traveler_id': travelerId,
      'traveler_name': travelerName,
      'traveler_email': travelerEmail,
      'documents': documents,
      'status': status.name,
      'verifier_id': verifierId,
      'verifier_name': verifierName,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'verifier_notes': verifierNotes,
    };
  }

  /// Create a copy with updated fields
  VerificationRequest copyWith({
    String? id,
    String? travelerId,
    String? travelerName,
    String? travelerEmail,
    Map<String, String>? documents,
    VerificationStatus? status,
    String? verifierId,
    String? verifierName,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? verifierNotes,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      travelerId: travelerId ?? this.travelerId,
      travelerName: travelerName ?? this.travelerName,
      travelerEmail: travelerEmail ?? this.travelerEmail,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      verifierId: verifierId ?? this.verifierId,
      verifierName: verifierName ?? this.verifierName,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifierNotes: verifierNotes ?? this.verifierNotes,
    );
  }

  /// Check if request has all required documents
  bool get hasAllDocuments {
    return documents.containsKey('government_id') &&
        documents.containsKey('selfie');
  }

  /// Get time elapsed since submission
  String get timeElapsed {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
