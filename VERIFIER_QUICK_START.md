# 🚀 Pasabay Verifier System - Quick Start

## ✨ What's New?

Your Pasabay app now has **TWO separate builds** in one project:

1. **📱 Traveler App (Mobile-First)** - For travelers to submit verification documents
2. **🖥️ Verifier Dashboard (Web-First)** - For verifiers to review and approve/reject requests

Both share the same codebase but run independently with complete access separation!

---

## 🎯 Quick Test (Both Apps)

Run this PowerShell script for easy testing:

```powershell
.\test_apps.ps1
```

Choose option **3** to run both apps simultaneously!

---

## 🏃 Manual Testing

### Test Traveler App (Mobile View)

```powershell
flutter run -t lib/main_traveler.dart -d chrome --web-port=5000
```

Open in Chrome: http://localhost:5000

### Test Verifier Dashboard (Web View)

```powershell
flutter run -t lib/main_verifier.dart -d chrome --web-port=8080
```

Open in Chrome: http://localhost:8080

---

## 📋 Setup Checklist

### Step 1: Database Setup ✅

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy and run: `migrations/setup_verifier_system.sql`
3. This creates:
   - `users` table with roles
   - `verification_requests` table
   - Security policies
   - Indexes

### Step 2: Create Verifier Account ✅

**In Supabase Dashboard:**

1. Go to **Authentication** → **Users** → **Add User**
2. Create account: `verifier@pasabay.com` (or your email)
3. Go to **SQL Editor** and run:

```sql
INSERT INTO users (id, email, role)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'verifier@pasabay.com'),
  'verifier@pasabay.com',
  'VERIFIER'
);
```

### Step 3: Test the Flow ✅

1. Run both apps (use `test_apps.ps1`)
2. **As Traveler:** Submit verification documents
3. **As Verifier:** Login → Review → Approve/Reject
4. **As Traveler:** Check status update

---

## 🎨 Features

### Traveler App (Mobile)
✅ Submit identity documents (ID + Selfie)  
✅ Track verification status  
✅ Resubmit if rejected  
✅ View rejection reasons  
❌ Cannot access from web browser  

### Verifier Dashboard (Web)
✅ View all verification requests  
✅ Filter by status (Pending, Approved, etc.)  
✅ View documents in full size  
✅ Approve with notes  
✅ Reject with reason  
✅ Real-time statistics  
❌ Cannot access from mobile  

---

## 🔒 Security Features

- **Platform Restrictions:** Mobile app blocked on web, verifier blocked on mobile
- **Role-Based Access:** Database-level permission checks
- **Row Level Security:** Supabase RLS policies enforce access
- **Authentication Required:** All operations require valid auth token

---

## 📦 Build for Production

### Build Mobile App (Android)

```powershell
flutter build apk -t lib/main_traveler.dart --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

### Build Verifier Dashboard (Web)

```powershell
flutter build web -t lib/main_verifier.dart --release
```

Output: `build\web\` (deploy to Netlify, Vercel, Firebase Hosting, etc.)

---

## 📁 Project Structure

```
lib/
├── main_traveler.dart          # Mobile app entry point
├── main_verifier.dart          # Web dashboard entry point
├── models/                     # Shared data models
│   ├── user_role.dart
│   ├── verification_status.dart
│   └── verification_request.dart
├── services/                   # Shared business logic
│   ├── auth_service.dart
│   └── verification_service.dart
└── verifier/                   # Verifier-specific UI
    ├── screens/
    │   ├── verifier_login_screen.dart
    │   ├── verifier_dashboard_screen.dart
    │   └── verification_detail_screen.dart
    └── widgets/
        ├── verification_card.dart
        └── statistics_card.dart
```

---

## 🔄 Verification Workflow

```
Traveler Submits → PENDING
        ↓
Verifier Opens → UNDER_REVIEW
        ↓
    ┌───┴───┐
    ↓       ↓
APPROVED  REJECTED
    ↓       ↓
Verified  Can Resubmit
```

---

## 🎓 Key Commands

| Action | Command |
|--------|---------|
| Run Traveler | `flutter run -t lib/main_traveler.dart -d chrome` |
| Run Verifier | `flutter run -t lib/main_verifier.dart -d chrome` |
| Build APK | `flutter build apk -t lib/main_traveler.dart` |
| Build Web | `flutter build web -t lib/main_verifier.dart` |
| Clean | `flutter clean` |
| Get Packages | `flutter pub get` |

---

## 🐛 Troubleshooting

### "Access Denied" on verifier login
**Fix:** Make sure user has VERIFIER role in database

```sql
UPDATE users SET role = 'VERIFIER' WHERE email = 'your-email@example.com';
```

### Can't run both apps
**Fix:** Use different ports

```powershell
flutter run -t lib/main_traveler.dart -d chrome --web-port=5000
flutter run -t lib/main_verifier.dart -d chrome --web-port=8080
```

### Build errors
**Fix:** Clean and rebuild

```powershell
flutter clean
flutter pub get
flutter run
```

---

## 📚 Documentation

- **Complete Guide:** `VERIFIER_SYSTEM_GUIDE.md`
- **Database Setup:** `migrations/setup_verifier_system.sql`
- **Test Script:** `test_apps.ps1`

---

## 🎉 What's Working

✅ **Separate Builds:** One codebase, two independent apps  
✅ **Platform Restrictions:** Mobile-only for travelers, web-only for verifiers  
✅ **Role-Based Access:** Database-enforced permissions  
✅ **Document Review:** Full-size image preview  
✅ **Approve/Reject:** With notes and reasons  
✅ **Real-time Stats:** Dashboard overview  
✅ **Shared Design:** Consistent Pasabay styling  
✅ **Chrome Testing:** Test both apps simultaneously  
✅ **Production Ready:** Build scripts for deployment  

---

## 🚀 Ready to Test?

1. **Setup Database:** Run the SQL migration
2. **Create Verifier:** Add a verifier account
3. **Run Test Script:** `.\test_apps.ps1` → Choose option 3
4. **Test Flow:** Submit → Review → Approve

---

## 💡 Next Steps

- Deploy verifier dashboard to web hosting
- Upload mobile app to Play Store / App Store
- Set up email notifications
- Add more verifiers
- Monitor verification metrics

---

**Built with ❤️ using Flutter and Supabase**

For detailed documentation, see `VERIFIER_SYSTEM_GUIDE.md`
