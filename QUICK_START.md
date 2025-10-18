# Pasabay App - Quick Start Guide (Supabase)

## Running the App

### ✅ Recommended: Run on Chrome (Web)
```bash
flutter run -d chrome
```
This works perfectly with Supabase and allows rapid development.

### Run on Android Emulator
```bash
# List available devices
flutter devices

# Run on Android
flutter run -d android
```

## Project Status

### ✅ Completed
- ✅ Project organization (screens, widgets, utils)
- ✅ **Supabase initialized successfully**
- ✅ SupabaseService utility class created
- ✅ Custom responsive UI components
- ✅ Landing, Login, and SignUp pages
- ✅ Email verification with 6-digit OTP
- ✅ Role selection (Traveler/Requester)
- ✅ Works on Chrome/Web
- ✅ Ready for Android/iOS deployment

### 🔄 Next Steps

1. **Set Up Supabase Database** ⚠️ REQUIRED
   - Go to https://supabase.com/dashboard
   - Select your project
   - Go to SQL Editor
   - Run the SQL script from `SUPABASE_GUIDE.md`

2. **Configure Email Templates** (Optional but Recommended)
   - Go to Authentication → Email Templates
   - Customize the Magic Link template
   - See `SUPABASE_GUIDE.md` for template code

3. **Test Authentication Flow**
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
├── main.dart                    # App entry (Supabase initialized ✅)
├── screens/
│   ├── landing_page.dart       # Welcome screen ✅
│   ├── signup_page.dart        # Registration with Supabase ✅
│   ├── login_page.dart         # Login with Supabase ✅
│   ├── verify_page.dart        # OTP verification ✅
│   └── role_selection_page.dart # Choose role ✅
├── widgets/
│   ├── responsive_wrapper.dart
│   ├── gradient_header.dart
│   ├── custom_button.dart
│   └── custom_input_field.dart
└── utils/
    ├── constants.dart          # App constants ✅
    ├── helpers.dart            # Validators ✅
    └── supabase_service.dart   # Supabase operations ✅
```

## Backend Configuration
- **Backend**: Supabase (replaced Firebase)
- **Authentication**: Email/Password with OTP verification ✅
- **Database**: PostgreSQL via Supabase ✅

## Known Issues
- None currently

## Resources
- `SUPABASE_GUIDE.md` - Complete Supabase integration documentation
- `PROJECT_ORGANIZATION.md` - Project structure details
- `README.md` - Project overview

## Support
- Supabase Dashboard: Check your project dashboard
- Flutter Documentation: https://docs.flutter.dev
- Supabase Documentation: https://supabase.com/docs
