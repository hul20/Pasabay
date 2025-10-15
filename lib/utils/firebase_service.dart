import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase service class for authentication and database operations
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Authentication Methods

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? middleInitial,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'middleInitial': middleInitial ?? '',
        'emailVerified': false,
        'role': null, // Will be set after role selection
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Save user role after selection
  Future<void> saveUserRole({required String uid, required String role}) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error saving user role: $e';
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
      }
    } catch (e) {
      throw 'Error sending verification email: $e';
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      await currentUser?.reload();
      return currentUser?.emailVerified ?? false;
    } catch (e) {
      throw 'Error checking email verification: $e';
    }
  }

  /// Generate and send 4-digit OTP
  Future<String> generateAndSendOTP(String email) async {
    try {
      // Generate 4-digit OTP
      final otp = _generateOTP();

      // Store OTP in Firestore with expiration time (5 minutes)
      await _firestore.collection('otps').doc(email).set({
        'otp': otp,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
        'verified': false,
      });

      // In production, you would send this via Firebase Functions + SendGrid/Mailgun
      // For development, we'll print it (check console)
      print('🔐 OTP for $email: $otp');
      print('⚠️ Note: In production, this will be sent via email');

      return otp;
    } catch (e) {
      throw 'Error generating OTP: $e';
    }
  }

  /// Generate random 4-digit OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  /// Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final otpDoc = await _firestore.collection('otps').doc(email).get();

      if (!otpDoc.exists) {
        throw 'No OTP found. Please request a new code.';
      }

      final data = otpDoc.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = data['expiresAt'] as int;
      final verified = data['verified'] as bool;

      // Check if already verified
      if (verified) {
        throw 'This OTP has already been used. Please request a new code.';
      }

      // Check if expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        throw 'OTP has expired. Please request a new code.';
      }

      // Verify OTP
      if (storedOTP != otp) {
        throw 'Invalid OTP. Please try again.';
      }

      // Mark as verified
      await _firestore.collection('otps').doc(email).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Error verifying OTP: $e';
    }
  }

  /// Update email verified status in Firestore
  Future<void> updateEmailVerifiedStatus(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error updating email verification status: $e';
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out: $e';
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        await currentUser!.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw 'Error updating profile: $e';
    }
  }

  // Firestore Methods

  /// Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw 'Error fetching user data: $e';
    }
  }

  /// Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw 'Error updating user data: $e';
    }
  }

  /// Stream of user data
  Stream<DocumentSnapshot> userDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Helper Methods

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// Check if user is signed in
  bool isUserSignedIn() {
    return currentUser != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return currentUser?.uid;
  }

  /// Reload current user
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }
}
