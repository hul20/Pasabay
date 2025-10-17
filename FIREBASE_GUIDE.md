# Firebase Integration Guide

## Overview
Firebase has been successfully initialized in the Pasabay app. This guide explains how to use Firebase Authentication and Firestore in your application.

## Setup Complete ✅

### What's Been Configured:
1. **Firebase Core** - Initialized in `main.dart`
2. **Firebase Auth** - Ready for user authentication
3. **Cloud Firestore** - Ready for database operations
4. **Firebase Options** - Auto-generated configuration for all platforms (Android, iOS, macOS, Web, Windows)
5. **Firebase Service** - Utility class for easy Firebase operations

### Files Created/Modified:
- `lib/firebase_options.dart` - Auto-generated Firebase configuration
- `lib/main.dart` - Firebase initialization added
- `lib/utils/firebase_service.dart` - Firebase service utility class

## Firebase Service Usage

### Getting the Firebase Service Instance

```dart
import 'package:pasabay_app/utils/firebase_service.dart';

final firebaseService = FirebaseService();
```

### Authentication Examples

#### 1. Sign Up with Email and Password

```dart
try {
  await firebaseService.signUpWithEmail(
    email: 'user@example.com',
    password: 'password123',
    firstName: 'John',
    lastName: 'Doe',
    middleInitial: 'M',
  );
  // Success - user account created and data saved to Firestore
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

#### 2. Sign In with Email and Password

```dart
try {
  UserCredential? userCredential = await firebaseService.signInWithEmail(
    email: 'user@example.com',
    password: 'password123',
  );
  // Success - user logged in
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

#### 3. Sign Out

```dart
try {
  await firebaseService.signOut();
  // Success - user logged out
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

#### 4. Reset Password

```dart
try {
  await firebaseService.resetPassword(email: 'user@example.com');
  // Success - password reset email sent
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

#### 5. Check Authentication State

```dart
// Check if user is signed in
bool isSignedIn = firebaseService.isUserSignedIn();

// Get current user
User? currentUser = firebaseService.currentUser;

// Get current user ID
String? userId = firebaseService.getCurrentUserId();

// Listen to auth state changes
firebaseService.authStateChanges.listen((User? user) {
  if (user == null) {
    print('User is signed out');
  } else {
    print('User is signed in: ${user.uid}');
  }
});
```

### Firestore Examples

#### 1. Get User Data

```dart
try {
  String userId = 'user-id-here';
  DocumentSnapshot userData = await firebaseService.getUserData(userId);
  
  if (userData.exists) {
    Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
    print('First Name: ${data['firstName']}');
    print('Last Name: ${data['lastName']}');
    print('Email: ${data['email']}');
  }
} catch (e) {
  print('Error: $e');
}
```

#### 2. Update User Data

```dart
try {
  String userId = firebaseService.getCurrentUserId()!;
  await firebaseService.updateUserData(userId, {
    'phoneNumber': '+1234567890',
    'address': '123 Main St',
  });
  // Success - user data updated
} catch (e) {
  print('Error: $e');
}
```

#### 3. Stream User Data (Real-time Updates)

```dart
String userId = firebaseService.getCurrentUserId()!;
firebaseService.userDataStream(userId).listen((DocumentSnapshot snapshot) {
  if (snapshot.exists) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    print('User data updated: $data');
  }
});
```

#### 4. Direct Firestore Access

```dart
// Get Firestore instance for advanced queries
FirebaseFirestore firestore = firebaseService.firestore;

// Example: Get all users
QuerySnapshot users = await firestore.collection('users').get();
for (var doc in users.docs) {
  print('User: ${doc.data()}');
}

// Example: Query with filters
QuerySnapshot activeUsers = await firestore
    .collection('users')
    .where('status', isEqualTo: 'active')
    .orderBy('createdAt', descending: true)
    .limit(10)
    .get();
```

## User Data Structure

When a user signs up, the following data is automatically stored in Firestore:

```dart
{
  'uid': 'user-unique-id',
  'email': 'user@example.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'middleInitial': 'M',
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
}
```

## Error Handling

The `FirebaseService` class includes built-in error handling for common authentication errors:

- `weak-password` - Password too weak
- `email-already-in-use` - Email already registered
- `invalid-email` - Invalid email format
- `user-not-found` - No account with this email
- `wrong-password` - Incorrect password
- `user-disabled` - Account disabled
- `too-many-requests` - Too many failed attempts
- `network-request-failed` - Network connection issue

## Integration with Existing Screens

### Example: Update SignUpPage to use Firebase

```dart
import '../utils/firebase_service.dart';

class _SignUpPageState extends State<SignUpPage> {
  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _firebaseService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          middleInitial: _middleInitialController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home or login page
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
```

### Example: Update LoginPage to use Firebase

```dart
import '../utils/firebase_service.dart';

class _LoginPageState extends State<LoginPage> {
  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _firebaseService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          // Navigate to home page
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
```

## Security Rules (To be set up in Firebase Console)

### Firestore Security Rules Example:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Allow users to read their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      // Allow users to update their own data
      allow update: if request.auth != null && request.auth.uid == userId;
      // Only allow user creation during signup (via backend/admin)
      allow create: if request.auth != null;
    }
  }
}
```

## Next Steps

1. **Test Authentication**
   - Run the app and test signup/login functionality
   - Check Firebase Console to verify users are being created

2. **Add More Features**
   - Email verification
   - Phone authentication
   - Google Sign-In
   - Profile picture upload to Firebase Storage

3. **Set Up Firestore Collections**
   - Design your data structure
   - Create collections for rides, deliveries, transactions, etc.

4. **Configure Security Rules**
   - Set up proper security rules in Firebase Console
   - Test rules thoroughly

5. **Add Analytics** (Optional)
   - Add Firebase Analytics to track user behavior
   - Monitor app performance with Firebase Performance Monitoring

## Testing Firebase

Run your app to test Firebase:

```bash
flutter run -d windows
```

Check Firebase Console to verify:
- Users are being created in Authentication
- User documents are being created in Firestore
- All platforms are properly registered

## Troubleshooting

### Common Issues:

1. **Build errors on Android**
   - Make sure `google-services.json` is in `android/app/`
   - Run `flutter clean` and rebuild

2. **Connection errors**
   - Check internet connection
   - Verify Firebase project is active in Console

3. **Authentication errors**
   - Enable Email/Password authentication in Firebase Console
   - Check security rules

4. **Firestore permission errors**
   - Update Firestore security rules
   - Verify user is authenticated before accessing Firestore

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Console](https://console.firebase.google.com)

---

**Firebase Status**: ✅ Initialized and Ready
**Last Updated**: January 2025
