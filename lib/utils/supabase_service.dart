import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// Supabase service class for authentication and database operations
class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Getters
  SupabaseClient get client => _supabase;
  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Authentication Methods

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? middleInitial,
  }) async {
    try {
      // Create user account with Supabase Auth (without email confirmation)
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Disable email confirmation link
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'middle_initial': middleInitial ?? '',
        },
      );

      if (response.user == null) {
        throw 'Failed to create account';
      }

      // Create user profile in public.users table
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'middle_initial': middleInitial ?? '',
        'email_verified': false,
        'role': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw 'Login failed';
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw 'Error signing out: $e';
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Check if email is verified
  bool isEmailVerified() {
    return currentUser?.emailConfirmedAt != null;
  }

  /// Send OTP via Supabase native email
  Future<void> sendOTP(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // Don't create new user, just send OTP
      );
      print('✅ OTP sent to $email via Supabase');
    } on AuthException catch (e) {
      // Provide more specific error messages
      if (e.message.contains('Email rate limit exceeded')) {
        throw 'Too many requests. Please wait a few minutes and try again.';
      } else if (e.message.contains('SMTP')) {
        throw 'Email service configuration error. Please contact support.';
      } else if (e.message.contains('magic link')) {
        throw 'Email sending failed. Please verify your email address and try again.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error sending OTP: $e');
      throw 'Failed to send verification code. Please check your email address and try again.';
    }
  }

  /// Verify OTP token
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );

      if (response.user == null) {
        throw 'Invalid verification code';
      }

      // Update user email verification status in users table
      await _supabase
          .from('users')
          .update({
            'email_verified': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', response.user!.id);

      print('✅ OTP verified successfully for $email');
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Verification failed: $e';
    }
  }

  /// Save user role
  Future<void> saveUserRole({required String role}) async {
    try {
      if (currentUser == null) throw 'No user logged in';

      await _supabase
          .from('users')
          .update({
            'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser!.id);
    } catch (e) {
      throw 'Error saving user role: $e';
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw 'Error fetching user data: $e';
    }
  }

  /// Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (currentUser == null) throw 'No user logged in';

      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').update(data).eq('id', currentUser!.id);
    } catch (e) {
      throw 'Error updating user data: $e';
    }
  }

  /// Stream of user data
  Stream<Map<String, dynamic>?> userDataStream() {
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', currentUser!.id)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // Helper Methods

  /// Handle Supabase Auth exceptions
  String _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('email not confirmed')) {
      return 'Please verify your email first';
    } else if (message.contains('user already registered')) {
      return 'This email is already registered';
    } else if (message.contains('invalid email')) {
      return 'Please enter a valid email address';
    } else if (message.contains('password')) {
      return 'Password must be at least 6 characters';
    } else {
      return e.message;
    }
  }

  /// Check if user is signed in
  bool isUserSignedIn() {
    return currentUser != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return currentUser?.id;
  }
}
