# ✅ Pasabay Verifier System - Setup Checklist

## 🚀 Quick Setup (15 minutes)

Use this checklist to get your verifier system up and running!

---

## Phase 1: Database Setup (5 minutes)

### Step 1.1: Run Migration
- [ ] Open Supabase Dashboard
- [ ] Navigate to **SQL Editor**
- [ ] Open file: `migrations/setup_verifier_system.sql`
- [ ] Copy entire content
- [ ] Paste in SQL Editor
- [ ] Click **Run** or press `Ctrl+Enter`
- [ ] Verify success message (should see "Success. No rows returned")

### Step 1.2: Verify Tables Created
- [ ] Go to **Table Editor** in Supabase
- [ ] Confirm `users` table exists
- [ ] Confirm `verification_requests` table exists
- [ ] Check that both tables have proper columns

### Step 1.3: Create Test Verifier Account
- [ ] Go to **Authentication** → **Users**
- [ ] Click **Add User** or **Invite User**
- [ ] Enter email (e.g., `verifier@test.com`)
- [ ] Enter password (e.g., `Test123!`)
- [ ] Click **Create User**

### Step 1.4: Assign Verifier Role
- [ ] Go to **SQL Editor**
- [ ] Run this query (replace email):
```sql
INSERT INTO users (id, email, role)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'verifier@test.com'),
  'verifier@test.com',
  'VERIFIER'
);
```
- [ ] Verify success

**✅ Database setup complete!**

---

## Phase 2: Local Testing (5 minutes)

### Step 2.1: Install Dependencies
- [ ] Open terminal in project folder
- [ ] Run: `flutter pub get`
- [ ] Wait for completion
- [ ] Verify no errors

### Step 2.2: Test Traveler App
- [ ] Open new terminal
- [ ] Run: `flutter run -t lib/main_traveler.dart -d chrome --web-port=5000`
- [ ] Wait for app to load
- [ ] Verify it opens in Chrome
- [ ] Should show "Mobile Only" warning OR landing page
- [ ] Leave this running

### Step 2.3: Test Verifier Dashboard
- [ ] Open another terminal
- [ ] Run: `flutter run -t lib/main_verifier.dart -d chrome --web-port=8080`
- [ ] Wait for app to load
- [ ] Verify it opens in Chrome
- [ ] Should show verifier login screen
- [ ] Leave this running

**✅ Both apps running!**

---

## Phase 3: Test Workflow (5 minutes)

### Step 3.1: Create Traveler Account
- [ ] Go to traveler app (localhost:5000)
- [ ] Click **Sign Up**
- [ ] Create test account: `traveler@test.com` / `Test123!`
- [ ] Verify email if required
- [ ] Login successfully

### Step 3.2: Submit Verification Request
- [ ] Navigate to **Identity Verification**
- [ ] Upload government ID (any test image)
- [ ] Upload selfie (any test image)
- [ ] Click **Submit**
- [ ] Verify submission success

### Step 3.3: Verify as Verifier
- [ ] Go to verifier dashboard (localhost:8080)
- [ ] Login with: `verifier@test.com` / `Test123!`
- [ ] Should see dashboard
- [ ] Check statistics (should show 1 pending)
- [ ] Click on the pending request
- [ ] View documents
- [ ] Click **Approve** (or **Reject**)
- [ ] Add optional notes
- [ ] Confirm action

### Step 3.4: Check Status as Traveler
- [ ] Go back to traveler app (localhost:5000)
- [ ] Refresh or navigate to profile
- [ ] Check verification status
- [ ] Should show "Approved" or "Rejected"

**✅ Complete workflow tested!**

---

## Phase 4: Access Control Testing (2 minutes)

### Test 4.1: Platform Restrictions
- [ ] Try accessing verifier URL (localhost:8080) from traveler app
- [ ] Should show "Web Only" message
- [ ] Try accessing traveler URL (localhost:5000) from verifier
- [ ] Should show "Mobile Only" message

### Test 4.2: Role Restrictions
- [ ] Logout from verifier dashboard
- [ ] Try logging in with traveler account
- [ ] Should show "Access Denied"
- [ ] Verify only verifier accounts can access dashboard

**✅ Security working!**

---

## Phase 5: Build for Production (Optional)

### Build 5.1: Mobile App (Android)
- [ ] Run: `flutter build apk -t lib/main_traveler.dart --release`
- [ ] Wait for build completion
- [ ] Find APK at: `build\app\outputs\flutter-apk\app-release.apk`
- [ ] Test APK on Android device

### Build 5.2: Web Dashboard
- [ ] Run: `flutter build web -t lib/main_verifier.dart --release`
- [ ] Wait for build completion
- [ ] Find output at: `build\web\`
- [ ] Deploy to Netlify/Vercel/Firebase Hosting

**✅ Production builds ready!**

---

## 🎯 Verification Checklist

Mark these as you verify each feature:

### Core Features
- [ ] ✅ Separate builds working (mobile & web)
- [ ] ✅ Platform restrictions enforced
- [ ] ✅ Role-based access working
- [ ] ✅ Traveler can submit documents
- [ ] ✅ Verifier can view requests
- [ ] ✅ Verifier can approve requests
- [ ] ✅ Verifier can reject requests
- [ ] ✅ Statistics display correctly
- [ ] ✅ Document preview working
- [ ] ✅ Status updates in real-time

### Security
- [ ] ✅ Authentication required
- [ ] ✅ Role validation working
- [ ] ✅ RLS policies active
- [ ] ✅ Unauthorized access blocked
- [ ] ✅ Platform restrictions working

### UI/UX
- [ ] ✅ Consistent design across apps
- [ ] ✅ Responsive layouts
- [ ] ✅ Status badges visible
- [ ] ✅ Forms working
- [ ] ✅ Buttons functional
- [ ] ✅ Navigation smooth

---

## 🐛 Troubleshooting Checklist

If something isn't working:

### Database Issues
- [ ] Verified SQL migration ran successfully?
- [ ] Checked for error messages in Supabase?
- [ ] Confirmed tables exist?
- [ ] Verified RLS policies are enabled?
- [ ] Double-checked verifier role assignment?

### App Issues
- [ ] Ran `flutter pub get`?
- [ ] Cleared build: `flutter clean`?
- [ ] Using correct entry point (-t flag)?
- [ ] Chrome is installed?
- [ ] Correct ports (5000 & 8080)?

### Login Issues
- [ ] Verified email/password correct?
- [ ] User exists in auth.users?
- [ ] User has role in users table?
- [ ] Role is exactly 'VERIFIER' (uppercase)?

### Access Issues
- [ ] Using correct URL (5000 vs 8080)?
- [ ] Logged in with correct account type?
- [ ] Role validation working?
- [ ] Browser cache cleared?

---

## 📚 Quick Reference

### URLs
```
Traveler App:      http://localhost:5000
Verifier Dashboard: http://localhost:8080
```

### Test Accounts (Create These)
```
Traveler:  traveler@test.com / Test123!
Verifier:  verifier@test.com / Test123!
```

### Commands
```powershell
# Run traveler
flutter run -t lib/main_traveler.dart -d chrome --web-port=5000

# Run verifier
flutter run -t lib/main_verifier.dart -d chrome --web-port=8080

# Quick test script
.\test_apps.ps1

# Build APK
flutter build apk -t lib/main_traveler.dart --release

# Build web
flutter build web -t lib/main_verifier.dart --release
```

---

## 🎉 Success Criteria

You're all set when:
- ✅ Both apps run without errors
- ✅ You can login to verifier dashboard
- ✅ Traveler can submit documents
- ✅ Verifier can approve/reject
- ✅ Status updates correctly
- ✅ Platform restrictions work
- ✅ Role validation works

---

## 📞 Need Help?

Check these files:
1. **Quick Start** → `VERIFIER_QUICK_START.md`
2. **Complete Guide** → `VERIFIER_SYSTEM_GUIDE.md`
3. **Architecture** → `ARCHITECTURE_DIAGRAM.md`
4. **Implementation** → `IMPLEMENTATION_COMPLETE.md`

---

## ⏱️ Time Estimate

- Database Setup: ~5 minutes
- Local Testing: ~5 minutes
- Workflow Test: ~5 minutes
- Access Control: ~2 minutes
- **Total: ~17 minutes**

---

## 🎯 Final Check

Before considering setup complete:
- [ ] Database tables created
- [ ] Verifier account created
- [ ] Both apps running
- [ ] Workflow tested end-to-end
- [ ] Access control verified
- [ ] Documentation reviewed

---

**When all checks are complete, you're ready to go! 🚀**

**Setup Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

*Last Updated: Implementation Complete*
*Version: 1.0*
