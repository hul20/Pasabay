# Pasabay App - Quick Start Guide

## Running the App

### ✅ Recommended: Run on Chrome (Web)
```bash
flutter run -d chrome
```
This works perfectly with Firebase and allows rapid development.

### Run on Android Emulator
```bash
# List available devices
flutter devices

# Run on Android
flutter run -d android
```

### ❌ Windows Desktop (Currently Not Working)
Windows build fails due to Firebase C++ SDK compatibility issues.
See `WINDOWS_BUILD_ISSUE.md` for details.

## Project Status

### ✅ Completed
- ✅ Project organization (screens, widgets, utils)
- ✅ Firebase initialized successfully
- ✅ FirebaseService utility class created
- ✅ Custom responsive UI components
- ✅ Landing, Login, and SignUp pages
- ✅ Works on Chrome/Web
- ✅ Ready for Android/iOS deployment

### 🔄 Next Steps
1. **Enable Email/Password Authentication** in Firebase Console
   - Go to https://console.firebase.google.com/project/pasabay-c7384
   - Navigate to Authentication → Sign-in method
   - Enable "Email/Password"

2. **Create Firestore Database**
   - Go to Firestore Database section
   - Create database (start in test mode for development)

3. **Integrate Firebase into Screens**
   - Update `lib/screens/signup_page.dart` to use `FirebaseService.signUpWithEmail()`
   - Update `lib/screens/login_page.dart` to use `FirebaseService.signInWithEmail()`
   - See `FIREBASE_GUIDE.md` for code examples

4. **Test Authentication Flow**
   - Test user registration
   - Test user login
   - Test data storage in Firestore

## Development Commands

```bash
# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Run on Chrome (recommended)
flutter run -d chrome

# Run on Android
flutter run -d android

# Check for errors
flutter analyze

# Format code
flutter format .

# Build for release (Android)
flutter build apk

# Build for release (Web)
flutter build web
```

## File Structure
```
lib/
├── main.dart                    # App entry (Firebase initialized ✅)
├── firebase_options.dart        # Auto-generated config ✅
├── screens/
│   ├── landing_page.dart       # Welcome screen ✅
│   ├── signup_page.dart        # Registration (needs Firebase integration)
│   └── login_page.dart         # Login (needs Firebase integration)
├── widgets/
│   ├── responsive_wrapper.dart
│   ├── gradient_header.dart
│   ├── custom_button.dart
│   └── custom_input_field.dart
└── utils/
    ├── constants.dart          # App constants ✅
    ├── helpers.dart            # Validators ✅
    └── firebase_service.dart   # Firebase operations ✅
```

## Firebase Configuration
- **Project ID**: pasabay-c7384
- **Platforms Configured**: Android, iOS, macOS, Web, Windows (5 platforms)
- **Authentication**: Email/Password (needs to be enabled in console)
- **Database**: Firestore (needs to be created)

## Known Issues
- ❌ **Windows desktop build fails** - Firebase C++ SDK compatibility issue
- ✅ **Solution**: Use Chrome for development

## Resources
- `FIREBASE_GUIDE.md` - Complete Firebase integration documentation
- `WINDOWS_BUILD_ISSUE.md` - Windows build issue explanation
- `PROJECT_ORGANIZATION.md` - Project structure details
- `README.md` - Project overview

## Support
- Check Firebase Console: https://console.firebase.google.com/project/pasabay-c7384
- Flutter Documentation: https://docs.flutter.dev
- Firebase Documentation: https://firebase.google.com/docs/flutter/setup
