# Supabase Email OTP Setup Guide

## ✅ Your Code is Already Configured!

Your app is fully set up to send and verify 6-digit OTP codes via email. Now you just need to configure your Supabase dashboard.

## 🔧 Required: Supabase Dashboard Configuration

### Step 1: Disable Email Confirmation

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: **czodfzjqkvpicbnhtqhv**
3. Click **Authentication** in the left sidebar
4. Click **Providers** tab
5. Find **Email** provider and expand it
6. **DISABLE** the toggle for **"Enable email confirmations"**
7. Click **Save**

**Why?** This prevents users from receiving a confirmation link email. They should only receive the 6-digit OTP.

### Step 2: Configure Email Templates (Optional but Recommended)

1. In Supabase Dashboard, go to **Authentication** → **Email Templates**
2. Find the **"Magic Link"** template (this is what Supabase uses for OTP emails)
3. Customize the email template to match your brand:

```html
<h2>Your Pasabay Verification Code</h2>
<p>Hi there,</p>
<p>Your verification code is:</p>
<h1 style="font-size: 32px; letter-spacing: 5px;">{{ .Token }}</h1>
<p>This code will expire in 60 seconds.</p>
<p>If you didn't request this code, you can safely ignore this email.</p>
<p>Thanks,<br>The Pasabay Team</p>
```

### Step 3: Run the Database SQL Script

**IMPORTANT:** You must create the `users` table in Supabase for the app to work.

1. Go to **SQL Editor** in Supabase Dashboard
2. Copy and paste the SQL from `SUPABASE_GUIDE.md` (lines 1-32)
3. Click **Run**

## 📧 How the Email OTP Works

### When User Signs Up:

1. **User fills signup form** → First name, last name, email, password
2. **System creates account** using `signUpWithEmail()`
3. **System immediately sends OTP** using `sendOTP(email)`
   - Supabase generates a **random 6-digit code**
   - Email is sent to user's Gmail
4. **User navigates to Verify Page**

### Email Contains:

```
Subject: Confirm Your Email - Pasabay

Your verification code is:

1 2 3 4 5 6

This code will expire in 60 seconds.
```

### When User Verifies:

1. **User opens Gmail** → Sees 6-digit code
2. **User enters code** in 6 input boxes in the app
3. **System calls** `verifyOTP(email, token)`
4. **Supabase verifies** the code matches and hasn't expired
5. **User proceeds** to role selection page

## 🧪 Testing the OTP Flow

### Test Steps:

1. **Run your app**:
   ```bash
   flutter run -d chrome
   ```

2. **Sign up with a real email address** (use your own Gmail)

3. **Check your Gmail inbox** (including spam folder)
   - You should receive an email from Supabase
   - Email contains a 6-digit code

4. **Enter the 6-digit code** in the app

5. **Verify success** → Should navigate to role selection

### Troubleshooting:

**Problem:** No email received
- ✅ Check spam/junk folder
- ✅ Verify email address is correct
- ✅ Check Supabase Dashboard → Authentication → Logs for errors
- ✅ Make sure "Enable email confirmations" is DISABLED

**Problem:** "Invalid verification code"
- ✅ Make sure you entered all 6 digits correctly
- ✅ Code expires after 60 seconds - request a new one
- ✅ Code can only be used once

**Problem:** Error sending OTP
- ✅ Check internet connection
- ✅ Verify Supabase credentials in `supabase_config.dart`
- ✅ Check Supabase Dashboard → Authentication → Settings

## 📱 Current Implementation Details

### Supabase Service Methods:

**`sendOTP(String email)`**
- Sends 6-digit OTP to email
- Uses Supabase's built-in `signInWithOtp()` method
- Code expires in 60 seconds
- Can be resent if needed

**`verifyOTP({required String email, required String token})`**
- Verifies the 6-digit code
- Updates `email_verified` field in database
- Returns authentication response
- Throws error if code is invalid/expired

### Verify Page Features:

- ✅ 6 input boxes for 6-digit code
- ✅ Auto-focus to next box when digit is entered
- ✅ Auto-focus to previous box when backspacing
- ✅ Resend code button (60-second cooldown)
- ✅ Loading indicator during verification
- ✅ Clear error messages
- ✅ Validates code is complete before submitting

## 🎯 What Makes This Secure

1. **Time-limited**: OTP expires in 60 seconds
2. **Single-use**: Each code can only be used once
3. **Email verification**: Proves user owns the email address
4. **Random generation**: Supabase generates cryptographically secure codes
5. **Rate limiting**: Supabase prevents spam/abuse

## 🚀 Next Steps

1. ✅ **Disable email confirmations** in Supabase Dashboard (REQUIRED)
2. ✅ **Run SQL script** to create users table (REQUIRED)
3. ✅ **Test signup flow** with your own email
4. ✅ **Customize email template** (Optional)
5. ✅ **Deploy your app** when ready

## 📝 Summary

Your app is **100% ready** to send 6-digit OTP codes via email! Just:

1. Disable "Enable email confirmations" in Supabase
2. Run the SQL script to create the users table
3. Test with a real email address

The OTP will arrive in Gmail within seconds! 📧✨
