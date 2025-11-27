import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet.dart';

/// Service for managing wallet operations
class WalletService {
  final _supabase = Supabase.instance.client;

  /// Get wallet for current user
  Future<Wallet?> getWallet() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ User not authenticated');
        throw Exception('User not authenticated');
      }

      print('🔍 Fetching wallet for user: $userId');

      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response == null) {
        print('⚠️ No wallet found for user - wallet may need to be created');
        return null;
      }

      print('✅ Wallet found: ${response['balance']}');
      return Wallet.fromJson(response);
    } catch (e) {
      print('❌ Error getting wallet: $e');
      rethrow;
    }
  }

  /// Top up wallet (add money)
  Future<Map<String, dynamic>> topUpWallet(double amount) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      print('💰 Processing top-up: ₱$amount for user: $userId');

      // Call the database function
      final response = await _supabase
          .rpc(
            'process_wallet_transaction',
            params: {
              'p_user_id': userId,
              'p_transaction_type': 'top_up',
              'p_amount': amount,
              'p_description': 'Wallet top-up',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Request timeout. Please check your connection.',
            ),
          );

      print('✅ Top-up response: $response');

      // Handle response
      if (response == null) {
        throw Exception('No response from server');
      }

      // Response is already a Map from the JSON function
      final Map<String, dynamic> result = response is Map<String, dynamic>
          ? response
          : {'success': false, 'error': 'Invalid response format'};

      if (result['success'] == true) {
        return {'success': true, 'balance_after': result['balance_after']};
      } else {
        throw Exception(result['error'] ?? 'Top-up failed');
      }
    } catch (e) {
      print('❌ Error topping up wallet: $e');
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Process payment (deduct money from wallet)
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    String? description,
    String? relatedRequestId,
    String? relatedTripId,
    String? relatedUserId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      // Call the database function
      final response = await _supabase.rpc(
        'process_wallet_transaction',
        params: {
          'p_user_id': userId,
          'p_transaction_type': 'payment',
          'p_amount': amount,
          'p_description': description ?? 'Payment',
          'p_related_user_id': relatedUserId,
          'p_related_request_id': relatedRequestId,
          'p_related_trip_id': relatedTripId,
        },
      );

      print('✅ Payment response: $response');

      if (response['success'] == true) {
        return {'success': true, 'balance_after': response['balance_after']};
      } else {
        throw Exception(response['error'] ?? 'Payment failed');
      }
    } catch (e) {
      print('❌ Error processing payment: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Add earning to traveler wallet
  Future<Map<String, dynamic>> addEarning({
    required String travelerId,
    required double amount,
    String? description,
    String? relatedRequestId,
    String? relatedTripId,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      // Call the database function
      final response = await _supabase.rpc(
        'process_wallet_transaction',
        params: {
          'p_user_id': travelerId,
          'p_transaction_type': 'earning',
          'p_amount': amount,
          'p_description': description ?? 'Service fee earned',
          'p_related_request_id': relatedRequestId,
          'p_related_trip_id': relatedTripId,
        },
      );

      print('✅ Earning response: $response');

      if (response['success'] == true) {
        return {'success': true, 'balance_after': response['balance_after']};
      } else {
        throw Exception(response['error'] ?? 'Adding earning failed');
      }
    } catch (e) {
      print('❌ Error adding earning: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Process refund (add money back to wallet)
  Future<Map<String, dynamic>> processRefund({
    required double amount,
    String? description,
    String? relatedRequestId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      // Call the database function
      final response = await _supabase.rpc(
        'process_wallet_transaction',
        params: {
          'p_user_id': userId,
          'p_transaction_type': 'refund',
          'p_amount': amount,
          'p_description': description ?? 'Refund',
          'p_related_request_id': relatedRequestId,
        },
      );

      print('✅ Refund response: $response');

      if (response['success'] == true) {
        return {'success': true, 'balance_after': response['balance_after']};
      } else {
        throw Exception(response['error'] ?? 'Refund failed');
      }
    } catch (e) {
      print('❌ Error processing refund: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get transaction history
  Future<List<WalletTransaction>> getTransactionHistory({
    int limit = 50,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get wallet first
      final walletResponse = await _supabase
          .from('wallets')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (walletResponse == null) {
        return [];
      }

      final walletId = walletResponse['id'] as String;

      // Get transactions
      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error getting transaction history: $e');
      return [];
    }
  }

  /// Check if user has sufficient balance
  Future<bool> hasSufficientBalance(double amount) async {
    try {
      final wallet = await getWallet();
      if (wallet == null) return false;
      return wallet.balance >= amount;
    } catch (e) {
      print('❌ Error checking balance: $e');
      return false;
    }
  }

  /// Subscribe to wallet changes
  RealtimeChannel subscribeToWallet(Function(Wallet) onWalletUpdate) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .channel('wallet:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wallets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            print('🔄 Wallet updated: ${payload.newRecord}');
            onWalletUpdate(Wallet.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }
}
