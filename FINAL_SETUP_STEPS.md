# ✅ Final Setup Steps - Pasabay App

## You're Almost Done! 🎉

Your SMTP is configured. Now complete these final steps:

---

## 🔧 Step 1: Disable Email Confirmations in Supabase

**CRITICAL: You must disable email confirmations so users only receive the 6-digit OTP**

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv)
2. Click **Authentication** (left sidebar)
3. Click **Providers** tab
4. Find **Email** provider and expand it
5. **DISABLE** the toggle: **"Enable email confirmations"**
6. Click **Save**

**Why?** This prevents users from getting TWO emails (confirmation link + OTP). They should only receive the 6-digit OTP code.

---

## 📊 Step 2: Create Database Table

You need to create the `users` table in Supabase:

1. Go to [SQL Editor](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/sql)
2. Click **"New query"**
3. Copy and paste this SQL:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  middle_initial TEXT,
  email_verified BOOLEAN DEFAULT FALSE,
  role TEXT CHECK (role IN ('Traveler', 'Requester')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can view their own data
CREATE POLICY "Users can view own data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own data"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own data
CREATE POLICY "Users can insert own data"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS users_email_idx ON public.users(email);
CREATE INDEX IF NOT EXISTS users_role_idx ON public.users(role);
```

4. Click **Run** (or press Ctrl+Enter)
5. You should see "Success. No rows returned"

---

## 🎨 Step 3: Customize Email Template (Optional but Recommended)

Make the OTP email look professional:

1. Go to [Email Templates](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/auth/templates)
2. Find **"Magic Link"** template (this is used for OTP)
3. Replace with this HTML:

```html
<h2>Welcome to Pasabay!</h2>
<p>Hi there,</p>
<p>Your verification code is:</p>
<h1 style="font-size: 36px; letter-spacing: 8px; color: #1a73e8; font-weight: bold; text-align: center; margin: 20px 0;">
  {{ .Token }}
</h1>
<p style="color: #666;">This code will expire in 60 minutes.</p>
<p style="color: #666;">If you didn't request this code, you can safely ignore this email.</p>
<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
<p style="color: #999; font-size: 12px;">
  Thanks,<br>
  The Pasabay Team
</p>
```

4. Click **Save**

---

## 🧪 Step 4: Test Your App

Now test the complete flow:

### Run the app:
```powershell
flutter run -d chrome
```

### Test Signup Flow:
1. Click **"Sign Up"** on landing page
2. Fill in the form:
   - First Name: **Test**
   - Last Name: **User**
   - Email: **YOUR REAL EMAIL** (use your actual email!)
   - Password: **Test1234!**
   - Confirm Password: **Test1234!**
3. Click **Continue**

### Check Your Email:
1. Open your email inbox (Gmail, Outlook, etc.)
2. Look for email from **Pasabay <noreply@pasabay.com>**
3. You should see a **6-digit code** like: **1 2 3 4 5 6**

### Enter OTP:
1. In the app, you'll see 6 input boxes
2. Enter the 6-digit code from your email
3. Click **Verify**
4. Success! You'll go to Role Selection page

### Complete Registration:
1. Choose **Traveler** or **Requester**
2. Click **Continue**
3. You should see the home page!

---

## 🐛 Troubleshooting

### Problem: No email received
**Solutions:**
- ✅ Check spam/junk folder
- ✅ Wait 1-2 minutes (SendGrid can be slow on first send)
- ✅ Verify SMTP settings in Supabase are saved
- ✅ Make sure "Enable email confirmations" is DISABLED
- ✅ Check [Supabase Logs](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/logs/edge-logs)

### Problem: "Invalid verification code"
**Solutions:**
- ✅ Make sure you entered all 6 digits correctly
- ✅ Code expires after 60 minutes - request a new one
- ✅ Each code can only be used once
- ✅ Check if you're using the latest code (not an old one)

### Problem: "Email already registered"
**Solutions:**
- ✅ Use a different email address
- ✅ Or delete the user from [Supabase Users](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/auth/users)

### Problem: Database error when signing up
**Solutions:**
- ✅ Make sure you ran the SQL script (Step 2)
- ✅ Check [Supabase Logs](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/logs/postgres-logs)
- ✅ Verify the `users` table exists in [Table Editor](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/editor)

### Problem: App crashes or errors
**Solutions:**
- ✅ Run `flutter clean` then `flutter pub get`
- ✅ Restart the app
- ✅ Check terminal for error messages
- ✅ Make sure supabase_config.dart has correct credentials

---

## 📋 Verification Checklist

Before testing, make sure:

- [x] ✅ SMTP configured in Supabase (you did this!)
- [ ] ⏳ "Enable email confirmations" is DISABLED in Supabase
- [ ] ⏳ SQL script ran successfully (users table created)
- [ ] ⏳ Email template customized (optional)
- [ ] ⏳ App tested with real email address

---

## 🎯 What Happens in Each Step

### 1. User Signs Up
```
SignUpPage → signUpWithEmail() → Creates account in Supabase Auth
          → sendOTP() → Sends 6-digit code to email via SendGrid
          → Navigate to VerifyPage
```

### 2. User Receives Email
```
SendGrid → User's Email Inbox
Subject: "Magic Link"
Body: Your code is: 1 2 3 4 5 6
```

### 3. User Enters OTP
```
VerifyPage → Enter 6 digits → verifyOTP() → Validates code
          → Updates email_verified = true
          → Navigate to RoleSelectionPage
```

### 4. User Selects Role
```
RoleSelectionPage → Select Traveler/Requester → saveUserRole()
                  → Navigate to TravelerHomePage or RequesterHomePage
```

---

## 🚀 Your App is Ready!

After completing these steps, your Pasabay app will:

✅ Send 6-digit OTP codes to users' emails via SendGrid
✅ Verify email addresses securely
✅ Allow users to choose their role (Traveler/Requester)
✅ Store user data in Supabase PostgreSQL database
✅ Work on web, Android, and iOS

---

## 📞 Need Help?

If you encounter any issues:

1. Check the error message in the app
2. Check terminal output for detailed errors
3. Check [Supabase Logs](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/logs)
4. Review the troubleshooting section above

---

## 🎊 Next Steps After Setup

Once everything works:

1. **Test all flows**: Signup → Verify → Role Selection → Login
2. **Customize**: Update colors, logos, text to match your brand
3. **Add features**: Build the actual marketplace functionality
4. **Deploy**: When ready, deploy to production

**Good luck with your Pasabay app! 🚀**
