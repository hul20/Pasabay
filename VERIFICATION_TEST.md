# Testing Identity Verification Flow

## 🎯 New Feature: Unverified Travelers Must Verify Identity

### What Changed?
When travelers log in, if they haven't completed identity verification, they'll be redirected to the Identity Verification screen instead of going directly to Traveler Home.

---

## 📋 Prerequisites

### 1. Run Database Migration First!

Go to Supabase Dashboard → SQL Editor:
https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/sql

Copy and paste this SQL, then click **Run**:

```sql
-- Add is_verified column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- Create verification_requests table
CREATE TABLE IF NOT EXISTS public.verification_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  id_type VARCHAR(50) NOT NULL,
  id_front_url TEXT NOT NULL,
  id_back_url TEXT,
  selfie_url TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own verification requests"
  ON public.verification_requests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own verification requests"
  ON public.verification_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS verification_requests_user_id_idx ON public.verification_requests(user_id);
CREATE INDEX IF NOT EXISTS verification_requests_status_idx ON public.verification_requests(status);
CREATE INDEX IF NOT EXISTS users_is_verified_idx ON public.users(is_verified);
```

---

## 🧪 Test Scenarios

### Test 1: New Traveler Flow ⭐

**Expected:** User sees Identity Verification screen after selecting Traveler role

**Steps:**
1. Run the app:
   ```bash
   flutter run -d chrome
   ```
2. Click **"Sign Up"**
3. Fill in user details and create account
4. Enter 6-digit OTP from email
5. Select **"Traveler"** role
6. ✅ **Should see Identity Verification screen** with:
   - "Verify Your Identity" title
   - Government ID requirement
   - Selfie Photo requirement
   - Security Notice
   - "Start Verification" button
   - "Verify Later" option
7. Click **"Verify Later"**
8. ✅ Should navigate to Traveler Home

---

### Test 2: Returning Unverified Traveler ⭐⭐

**Expected:** User is redirected to verification screen on login

**Setup:**
- Use a traveler account that already exists but hasn't verified identity
- Make sure `is_verified = false` in database

**Steps:**
1. If logged in, log out first
2. Click **"Log In"**
3. Enter traveler email and password
4. ✅ **Should be redirected to Identity Verification screen** (NOT Traveler Home)
5. This proves unverified travelers can't bypass verification

**Verify in Database:**
```sql
SELECT email, role, is_verified 
FROM users 
WHERE email = 'your_test_email@example.com';
-- Should show: role = 'Traveler', is_verified = false
```

---

### Test 3: Verified Traveler ✅

**Expected:** User goes directly to Traveler Home

**Setup:**
1. First, manually verify a traveler in Supabase:
   ```sql
   UPDATE users 
   SET is_verified = true 
   WHERE email = 'test_traveler@example.com';
   ```

**Steps:**
1. Log out
2. Log in with the verified traveler account
3. ✅ **Should go directly to Traveler Home** (skips verification screen)

---

### Test 4: Requester Flow (No Verification Needed)

**Expected:** Requesters never see verification screen

**Steps:**
1. Sign up or log in
2. Select **"Requester"** role
3. ✅ Should go directly to Requester Home
4. No verification screen appears (requesters don't need identity verification)

---

## 📊 Expected Results Table

| User Type | Email Verified | Role | is_verified | Login Destination |
|-----------|----------------|------|-------------|-------------------|
| New User | ❌ | - | ❌ | Email Verification Page |
| Verified Email | ✅ | - | ❌ | Role Selection Page |
| **New Traveler** | ✅ | **Traveler** | ❌ | **Identity Verification** ⭐ |
| **Unverified Traveler (Returning)** | ✅ | **Traveler** | ❌ | **Identity Verification** ⭐ |
| Verified Traveler | ✅ | Traveler | ✅ | Traveler Home |
| Requester | ✅ | Requester | - | Requester Home |

---

## 🔍 Verification Checklist

After running tests, verify:

- [ ] New travelers see verification screen after role selection
- [ ] Unverified travelers can't login without seeing verification screen
- [ ] "Verify Later" button navigates to Traveler Home
- [ ] "Start Verification" shows "coming soon" message
- [ ] Verified travelers skip verification screen
- [ ] Requesters never see verification screen
- [ ] UI matches Figma design

---

## 🐛 Troubleshooting

### Issue: "Column 'is_verified' doesn't exist"
**Solution:** Run the migration SQL in Supabase Dashboard (see Prerequisites)

### Issue: Always going to Traveler Home (not verification)
**Solution:** 
```sql
-- Check current status
SELECT email, role, is_verified FROM users WHERE email = 'test@example.com';

-- Force reset
UPDATE users SET is_verified = false WHERE email = 'test@example.com';
```

### Issue: Not redirecting to verification screen
**Solution:**
1. Check that user role is exactly "Traveler" (case-sensitive)
2. Verify `is_verified` is `false` in database
3. Check browser console for errors
4. Restart the app

### Issue: Can't see verification screen UI
**Solution:**
1. Verify file exists: `lib/screens/traveler/identity_verification_screen.dart`
2. Check import in `login_page.dart`: `import 'traveler/identity_verification_screen.dart';`
3. Run `flutter clean` then `flutter run`

---

## 🔄 Reset Test User

To reset a traveler for retesting:

```sql
-- Reset verification status
UPDATE users 
SET is_verified = false 
WHERE email = 'test@example.com';

-- Delete any verification requests (if implemented)
DELETE FROM verification_requests 
WHERE user_id = (
  SELECT id FROM users WHERE email = 'test@example.com'
);
```

---

## 📝 What's Coming Next?

After verification flow testing passes:
1. ✅ Identity verification UI (Done)
2. ✅ Login redirection logic (Done)
3. 🚧 Document upload functionality
4. 🚧 Supabase Storage integration
5. 🚧 Admin verification review interface
6. 🚧 Verification status notifications

---

## 🎬 Quick Demo Flow

**Complete end-to-end test:**
1. Sign up as new user
2. Verify email with OTP
3. Select "Traveler" role → See verification screen
4. Click "Verify Later" → Access Traveler Home
5. Log out
6. Log back in → Redirected to verification screen again
7. ✅ This confirms unverified travelers must verify!
