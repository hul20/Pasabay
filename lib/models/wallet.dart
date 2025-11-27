import 'package:flutter/foundation.dart';

/// Wallet model for user balance
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: _parseDecimal(json['balance']),
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
      'user_id': userId,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted balance (e.g., "₱1,234.56")
  String get formattedBalance => '₱${balance.toStringAsFixed(2)}';
}

/// Transaction type enum
enum TransactionType {
  topUp,
  payment,
  refund,
  earning,
  withdrawal;

  String get value {
    switch (this) {
      case TransactionType.topUp:
        return 'top_up';
      case TransactionType.payment:
        return 'payment';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.earning:
        return 'earning';
      case TransactionType.withdrawal:
        return 'withdrawal';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.topUp:
        return 'Top Up';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.earning:
        return 'Earning';
      case TransactionType.withdrawal:
        return 'Withdrawal';
    }
  }

  bool get isCredit {
    return this == TransactionType.topUp ||
        this == TransactionType.refund ||
        this == TransactionType.earning;
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'top_up':
        return TransactionType.topUp;
      case 'payment':
        return TransactionType.payment;
      case 'refund':
        return TransactionType.refund;
      case 'earning':
        return TransactionType.earning;
      case 'withdrawal':
        return TransactionType.withdrawal;
      default:
        return TransactionType.topUp;
    }
  }
}

/// Wallet transaction model
class WalletTransaction {
  final String id;
  final String walletId;
  final TransactionType transactionType;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? relatedUserId;
  final String? relatedRequestId;
  final String? relatedTripId;
  final String? description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.transactionType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.relatedUserId,
    this.relatedRequestId,
    this.relatedTripId,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      transactionType: TransactionType.fromString(
        json['transaction_type'] as String,
      ),
      amount: _parseDecimal(json['amount']),
      balanceBefore: _parseDecimal(json['balance_before']),
      balanceAfter: _parseDecimal(json['balance_after']),
      relatedUserId: json['related_user_id'] as String?,
      relatedRequestId: json['related_request_id'] as String?,
      relatedTripId: json['related_trip_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'wallet_id': walletId,
      'transaction_type': transactionType.value,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'related_user_id': relatedUserId,
      'related_request_id': relatedRequestId,
      'related_trip_id': relatedTripId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get formatted amount (e.g., "₱1,234.56" or "-₱1,234.56")
  String get formattedAmount {
    final prefix = transactionType.isCredit ? '+' : '-';
    return '$prefix₱${amount.toStringAsFixed(2)}';
  }

  /// Get formatted date (e.g., "Nov 27, 2025")
  String get formattedDate {
    // Convert to local time
    final localTime = createdAt.toLocal();
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
    return '${months[localTime.month - 1]} ${localTime.day}, ${localTime.year}';
  }

  /// Get formatted time (e.g., "2:30 PM")
  String get formattedTime {
    // Convert to local time
    final localTime = createdAt.toLocal();
    final hour = localTime.hour > 12 ? localTime.hour - 12 : localTime.hour;
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
}
