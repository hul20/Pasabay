# Pasabay Verifier System - Complete Guide

## Overview

This implementation separates the Pasabay app into two distinct builds:
1. **Traveler App (Mobile)** - For travelers to submit verification documents
2. **Verifier Dashboard (Web)** - For verifiers to review and approve/reject documents

Both builds share the same codebase but have separate entry points and are restricted to their respective platforms.

---

## Project Structure

```
lib/
├── main_traveler.dart              # Entry point for mobile traveler app
├── main_verifier.dart              # Entry point for web verifier dashboard
├── models/
│   ├── user_role.dart             # User roles enum (TRAVELER, VERIFIER, etc.)
│   ├── verification_status.dart   # Verification status enum
│   └── verification_request.dart  # Verification request model
├── services/
│   ├── auth_service.dart          # Authentication and user role management
│   └── verification_service.dart  # Verification request operations
├── verifier/
│   ├── screens/
│   │   ├── verifier_login_screen.dart       # Verifier login page
│   │   ├── verifier_dashboard_screen.dart   # Main dashboard with requests list
│   │   └── verification_detail_screen.dart  # Request detail and approval page
│   └── widgets/
│       ├── verification_card.dart           # Request card widget
│       └── statistics_card.dart             # Statistics card widget
└── (existing traveler files remain unchanged)
```

---

## Running the Applications

### 1. Run Traveler App (Mobile) in Chrome

```powershell
flutter run -t lib/main_traveler.dart -d chrome
```

This will run the mobile app in Chrome with device emulation. You can open Chrome DevTools (F12) and toggle device toolbar to test mobile experience.

### 2. Run Verifier Dashboard (Web) in Chrome

```powershell
flutter run -t lib/main_verifier.dart -d chrome --web-port=8080
```

This runs the web verifier dashboard on port 8080. You can run both simultaneously on different ports.

### 3. Test Both at the Same Time

**Terminal 1:**
```powershell
flutter run -t lib/main_traveler.dart -d chrome --web-port=5000
```

**Terminal 2:**
```powershell
flutter run -t lib/main_verifier.dart -d chrome --web-port=8080
```

---

## Building for Production

### Build Mobile App (Android APK)

```powershell
flutter build apk -t lib/main_traveler.dart --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Mobile App (iOS)

```powershell
flutter build ios -t lib/main_traveler.dart --release
```

### Build Web Verifier Dashboard

```powershell
flutter build web -t lib/main_verifier.dart --release
```

Output: `build/web/` (deploy this folder to your web hosting)

---

## Database Setup

### 1. Run Migration in Supabase

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open and run the migration file: `migrations/setup_verifier_system.sql`

This will create:
- `users` table with role management
- `verification_requests` table
- Indexes for performance
- Row Level Security (RLS) policies
- Automatic timestamp triggers

### 2. Create a Verifier Account

**Option A: Via Supabase Dashboard**
1. Go to **Authentication** > **Users**
2. Click **Invite User** or **Add User**
3. Create user with email (e.g., `verifier@pasabay.com`)
4. Go to **SQL Editor** and run:

```sql
INSERT INTO users (id, email, role)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'verifier@pasabay.com'),
  'verifier@pasabay.com',
  'VERIFIER'
);
```

**Option B: Programmatically**
```dart
// In your admin panel or setup script
await authService.signUp(
  'verifier@pasabay.com',
  'SecurePassword123!',
  UserRole.VERIFIER,
);
```

---

## Features

### Traveler App (Mobile)
- ✅ Submit identity verification documents
- ✅ View verification status
- ✅ Resubmit documents if rejected
- ✅ Blocked from web access

### Verifier Dashboard (Web)
- ✅ View all verification requests
- ✅ Filter by status (Pending, Approved, Rejected, etc.)
- ✅ View detailed request information
- ✅ View submitted documents (full-size preview)
- ✅ Approve requests with optional notes
- ✅ Reject requests with reason and notes
- ✅ Real-time statistics dashboard
- ✅ Blocked from mobile access

---

## Verification Workflow

```
1. Traveler submits documents → Status: PENDING
                                      ↓
2. Verifier opens request → Status: UNDER_REVIEW (auto-assigned)
                                      ↓
3. Verifier reviews documents
                    ├──────────────────┬──────────────────┐
                    ↓                  ↓                  ↓
        4a. Approve          4b. Reject         4c. Leave pending
         Status: APPROVED    Status: REJECTED   Status: UNDER_REVIEW
         User verified ✓     Can resubmit       Can review later
```

---

## Access Control

### Platform Restrictions

**Traveler App:**
- ✅ Allowed: Android, iOS
- ❌ Blocked: Web (shows "Mobile Only" message)

**Verifier Dashboard:**
- ✅ Allowed: Web browsers
- ❌ Blocked: Mobile (shows "Web Only" message)

### Role-Based Access

**Travelers can:**
- Submit verification requests
- View their own requests
- Resubmit if rejected

**Verifiers can:**
- View all verification requests
- Review documents
- Approve/reject requests
- Add notes and rejection reasons

**Enforced by:**
- Supabase Row Level Security (RLS)
- Flutter role checks
- Auth guards on routes

---

## API Reference

### AuthService

```dart
// Get current user role
final role = await authService.getCurrentUserRole();

// Check if user is verifier
final isVerifier = await authService.isVerifier();

// Sign in
await authService.signIn(email, password);

// Sign out
await authService.signOut();
```

### VerificationService

```dart
// Submit new verification request
await verificationService.submitVerificationRequest(
  travelerId: userId,
  travelerName: name,
  travelerEmail: email,
  documents: {'government_id': url, 'selfie': url},
);

// Get all requests (verifiers only)
final requests = await verificationService.getAllRequests();

// Filter by status
final pending = await verificationService.getAllRequests(
  status: VerificationStatus.PENDING,
);

// Approve request
await verificationService.approveRequest(
  requestId,
  verifierId,
  notes,
);

// Reject request
await verificationService.rejectRequest(
  requestId,
  verifierId,
  reason,
  notes,
);

// Get statistics
final stats = await verificationService.getStatistics();
```

---

## Testing Guide

### Test Scenario 1: Complete Verification Flow

1. **Run both apps:**
   ```powershell
   # Terminal 1
   flutter run -t lib/main_traveler.dart -d chrome --web-port=5000
   
   # Terminal 2
   flutter run -t lib/main_verifier.dart -d chrome --web-port=8080
   ```

2. **As Traveler (Port 5000):**
   - Sign up/login as traveler
   - Navigate to identity verification
   - Upload government ID and selfie
   - Submit verification request

3. **As Verifier (Port 8080):**
   - Login with verifier credentials
   - View new request in dashboard
   - Click "View Details"
   - Review documents
   - Approve or reject

4. **Back to Traveler:**
   - Check verification status
   - See approval or rejection message

### Test Scenario 2: Access Control

1. **Try accessing verifier dashboard from mobile:**
   - Should show "Web Only" message

2. **Try accessing traveler app from web (non-verifier account):**
   - Should show "Mobile Only" message

3. **Try accessing verifier dashboard with traveler account:**
   - Should show "Access Denied" message

---

## Styling and Design

Both apps share the same design system from `utils/constants.dart`:

- **Primary Color:** `#00AAF3` (Pasabay blue)
- **Secondary Color:** `#0083B0`
- **Font Family:** Inter
- **Border Radius:** 17px (default), 9.5px (inputs)

The verifier dashboard adapts the mobile design to a web-first layout with:
- Cards for organization
- Responsive grid for statistics
- Full-width detail views
- Proper spacing for desktop screens

---

## Deployment Checklist

### Mobile App (Traveler)
- [ ] Build release APK/IPA
- [ ] Test on real devices
- [ ] Configure app signing
- [ ] Upload to Google Play / App Store
- [ ] Set proper permissions in manifest

### Web Dashboard (Verifier)
- [ ] Build web release
- [ ] Deploy to hosting (Netlify, Vercel, Firebase Hosting, etc.)
- [ ] Configure domain and SSL
- [ ] Set up environment variables
- [ ] Enable CORS if needed
- [ ] Test on different browsers

### Database
- [ ] Run migration SQL
- [ ] Create verifier accounts
- [ ] Set up backups
- [ ] Configure RLS policies
- [ ] Test permissions
- [ ] Set up monitoring

---

## Troubleshooting

### Issue: "Access Denied" when logging into verifier dashboard

**Solution:** Ensure user has VERIFIER role in database:
```sql
UPDATE users SET role = 'VERIFIER' WHERE email = 'your-email@example.com';
```

### Issue: Documents not loading

**Solution:** Check Supabase Storage permissions and CORS settings

### Issue: Can't run both apps simultaneously

**Solution:** Use different ports:
```powershell
flutter run -t lib/main_traveler.dart -d chrome --web-port=5000
flutter run -t lib/main_verifier.dart -d chrome --web-port=8080
```

### Issue: Build fails

**Solution:** Clean and rebuild:
```powershell
flutter clean
flutter pub get
flutter run -t lib/main_traveler.dart -d chrome
```

---

## Security Considerations

1. **Row Level Security (RLS)** is enabled on all tables
2. **Role-based access** is enforced at database level
3. **Platform restrictions** prevent unauthorized access
4. **Authentication required** for all operations
5. **Document URLs** should use Supabase Storage with proper permissions

---

## Future Enhancements

- [ ] Email notifications for status changes
- [ ] Batch approval/rejection
- [ ] Document annotation tools
- [ ] Advanced filtering and search
- [ ] Export reports
- [ ] Analytics dashboard
- [ ] Verifier performance metrics
- [ ] Automated document verification (AI)

---

## Support

For issues or questions:
1. Check this documentation
2. Review Supabase logs
3. Check Flutter error messages
4. Review RLS policies in Supabase

---

**Built with Flutter 💙 | Powered by Supabase 🚀**
