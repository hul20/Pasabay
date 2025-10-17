# 🚨 Fix: "Error sending magic link email"

## Root Cause
Your Supabase project cannot send emails because of SMTP configuration issues.

---

## ✅ SOLUTION 1: Fix SendGrid Configuration (Recommended)

### Step 1: Verify Sender Email in SendGrid

1. Go to [SendGrid Dashboard](https://app.sendgrid.com)
2. Click **Settings** → **Sender Authentication**
3. Click **Verify a Single Sender**
4. Enter:
   - From Name: `Pasabay`
   - From Email: `noreply@pasabay.com` (or use your domain)
   - Reply To: (same as From Email)
5. Click **Create**
6. **Check your email** and click the verification link

### Step 2: Update Supabase SMTP Settings

1. Go to [Supabase SMTP Settings](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/settings/auth)
2. Scroll to **SMTP Settings**
3. Update to match your verified SendGrid email:

```
Enable Custom SMTP: ✅ ON
Host: smtp.sendgrid.net
Port: 587
Username: apikey
Password: [Your SendGrid API Key]
Sender email: noreply@pasabay.com  (must match verified sender)
Sender name: Pasabay
```

4. Click **Save**

---

## ✅ SOLUTION 2: Use Gmail (Quick Testing)

### Step 1: Generate Gmail App Password

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** (if not already)
3. Go to **App passwords**
4. Generate password for "Mail" → "Other (Pasabay)"
5. Copy the 16-character password

### Step 2: Update Supabase SMTP

1. Go to [Supabase SMTP Settings](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/settings/auth)
2. Use these settings:

```
Enable Custom SMTP: ✅ ON
Host: smtp.gmail.com
Port: 587
Username: your-email@gmail.com
Password: [16-char app password]
Sender email: your-email@gmail.com
Sender name: Pasabay
```

3. Click **Save**

---

## ✅ SOLUTION 3: Use Supabase Default (Limited)

If you just want to test quickly:

1. Go to [Supabase SMTP Settings](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/settings/auth)
2. **Disable Custom SMTP**
3. This uses Supabase's built-in email service
4. **Limitation:** Only 4 emails per hour

---

## 🧪 Test After Configuration

### In Supabase Dashboard:
1. Go to **Authentication** → **Users**
2. Click **Invite user**
3. Enter your email
4. Check if email arrives

### In Your App:
1. Run: `flutter run -d chrome`
2. Click **Sign Up**
3. Enter your details
4. Check your email inbox (and spam folder)

---

## 🔍 Still Getting Errors?

### Check Supabase Logs:
1. Go to [Logs](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/logs/edge-logs)
2. Look for SMTP or email errors
3. The detailed error message will show what's wrong

### Common Issues:

**"Email rate limit exceeded"**
- Wait 1 hour between sends
- Or upgrade your Supabase plan

**"Invalid SMTP credentials"**
- Double-check your SendGrid API key
- Make sure you copied it completely
- Try regenerating a new API key

**"Sender not verified"**
- Verify your sender email in SendGrid
- Check verification email from SendGrid

**"Connection refused"**
- Check port number (should be 587)
- Verify hostname is correct

---

## 📧 What Email Should You Use?

### For Development/Testing:
- ✅ Use Gmail with app password (quick setup)
- ✅ Test with your own email first

### For Production:
- ✅ Use custom domain email via SendGrid
- ✅ Verify sender in SendGrid
- ✅ Set up proper DNS records (SPF, DKIM)

---

## 🎯 Quick Fix (Right Now!)

**The fastest way to get it working:**

1. **Disable Custom SMTP** in Supabase (temporarily)
2. This uses Supabase's default email
3. Test your signup flow
4. You'll get 4 emails/hour - enough for testing
5. Later, set up SendGrid properly for production

**Click here:** [Supabase SMTP Settings](https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/settings/auth)

Toggle **"Enable Custom SMTP"** to **OFF**

Click **Save**

Then try signing up again!

---

## ✅ Checklist

- [ ] SMTP settings saved in Supabase
- [ ] Sender email verified (if using SendGrid)
- [ ] Test email sent from Supabase dashboard
- [ ] App tested with real email address
- [ ] Email received (check spam folder)

---

**Need more help?** Check the Supabase logs for the exact error message.
