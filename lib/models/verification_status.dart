import 'package:flutter/material.dart';

/// Status of a verification request
enum VerificationStatus {
  PENDING,
  UNDER_REVIEW,
  APPROVED,
  REJECTED,
  RESUBMITTED;

  /// Get the database value (Title Case for database constraint)
  String get dbValue {
    switch (this) {
      case VerificationStatus.PENDING:
        return 'Pending';
      case VerificationStatus.UNDER_REVIEW:
        return 'Under Review';
      case VerificationStatus.APPROVED:
        return 'Approved';
      case VerificationStatus.REJECTED:
        return 'Rejected';
      case VerificationStatus.RESUBMITTED:
        return 'Resubmitted';
    }
  }

  String get displayName {
    switch (this) {
      case VerificationStatus.PENDING:
        return 'Pending Review';
      case VerificationStatus.UNDER_REVIEW:
        return 'Under Review';
      case VerificationStatus.APPROVED:
        return 'Approved';
      case VerificationStatus.REJECTED:
        return 'Rejected';
      case VerificationStatus.RESUBMITTED:
        return 'Resubmitted';
    }
  }

  Color get color {
    switch (this) {
      case VerificationStatus.PENDING:
        return Colors.orange;
      case VerificationStatus.UNDER_REVIEW:
        return Colors.blue;
      case VerificationStatus.APPROVED:
        return Colors.green;
      case VerificationStatus.REJECTED:
        return Colors.red;
      case VerificationStatus.RESUBMITTED:
        return Colors.amber;
    }
  }

  IconData get icon {
    switch (this) {
      case VerificationStatus.PENDING:
        return Icons.schedule;
      case VerificationStatus.UNDER_REVIEW:
        return Icons.visibility;
      case VerificationStatus.APPROVED:
        return Icons.check_circle;
      case VerificationStatus.REJECTED:
        return Icons.cancel;
      case VerificationStatus.RESUBMITTED:
        return Icons.refresh;
    }
  }

  static VerificationStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return VerificationStatus.PENDING;
      case 'UNDER_REVIEW':
        return VerificationStatus.UNDER_REVIEW;
      case 'APPROVED':
        return VerificationStatus.APPROVED;
      case 'REJECTED':
        return VerificationStatus.REJECTED;
      case 'RESUBMITTED':
        return VerificationStatus.RESUBMITTED;
      default:
        return VerificationStatus.PENDING;
    }
  }
}
