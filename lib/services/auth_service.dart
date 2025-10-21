import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';

/// Service for handling authentication and user role management
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get user role from database
  Future<UserRole?> getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (response['role'] != null) {
        return UserRole.fromString(response['role'] as String);
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Get current user's role
  Future<UserRole?> getCurrentUserRole() async {
    if (currentUserId == null) return null;
    return getUserRole(currentUserId!);
  }

  /// Check if current user is a verifier
  Future<bool> isVerifier() async {
    final role = await getCurrentUserRole();
    return role == UserRole.VERIFIER;
  }

  /// Check if current user is a traveler
  Future<bool> isTraveler() async {
    final role = await getCurrentUserRole();
    return role == UserRole.TRAVELER;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp(
    String email,
    String password,
    UserRole role,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Create user record with role
    if (response.user != null) {
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'role':
            role.displayName, // Save as Title Case to match database constraint
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase.from('users').update(updates).eq('id', userId);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
