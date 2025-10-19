# Create Verifier Account (Admin Only)

## 🔒 Security Notice
Verifier accounts can **ONLY** be created by administrators through the Supabase Dashboard. There is no public signup option for verifiers to maintain security and control.

---

## 📋 How to Create a Verifier Account

### Step 1: Create Auth User in Supabase

1. Go to your **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your **Pasabay** project
3. Navigate to **Authentication** → **Users**
4. Click **"Add User"** or **"Invite User"**
5. Fill in the details:
   - **Email**: The verifier's email (e.g., `verifier@pasabay.com`)
   - **Password**: Create a secure password (you'll provide this to the verifier)
   - **Auto Confirm User**: ✅ Check this (skips email verification)
6. Click **"Create User"**
7. **Copy the User ID** - you'll need this in the next step

### Step 2: Add User to Users Table with VERIFIER Role

Go to **SQL Editor** in Supabase and run this query:

```sql
-- Replace with actual values
INSERT INTO users (id, email, role, full_name, created_at, updated_at)
VALUES (
  'USER_ID_FROM_STEP_1',              -- Paste the user ID from Step 1
  'verifier@pasabay.com',             -- Same email as Step 1
  'VERIFIER',                         -- Must be exactly 'VERIFIER' (all caps)
  'John Verifier',                    -- Optional: Full name
  NOW(),
  NOW()
);
```

### Step 3: Verify the Account

1. Check the **users** table (Table Editor → users)
2. Confirm the new row exists with:
   - Correct `id` (matches auth user)
   - Correct `email`
   - `role` = `'VERIFIER'`

### Step 4: Provide Credentials to Verifier

Send the verifier their login credentials securely:
- **Login URL**: http://localhost:8082 (or your production URL)
- **Email**: The email you created
- **Password**: The password you set (recommend they change it after first login)

---

## 🚀 Quick Creation Script

For faster creation, use this combined SQL script:

```sql
-- Step 1: Get the user ID from auth.users
-- (Run this AFTER creating the user in Authentication UI)
SELECT id, email FROM auth.users WHERE email = 'verifier@pasabay.com';

-- Step 2: Insert into users table with the ID from above
INSERT INTO users (id, email, role, full_name, created_at, updated_at)
VALUES (
  '00000000-0000-0000-0000-000000000000',  -- Replace with actual user ID
  'verifier@pasabay.com',
  'VERIFIER',
  'Verifier Name',
  NOW(),
  NOW()
);

-- Step 3: Verify the insertion
SELECT * FROM users WHERE email = 'verifier@pasabay.com';
```

---

## ✅ Testing the Verifier Account

1. **Open verifier app**: http://localhost:8082 (or production URL)
2. **Sign in** with the credentials:
   - Email: verifier@pasabay.com
   - Password: (the one you created)
3. **Expected result**: 
   - ✅ Should redirect to Verifier Dashboard
   - ✅ Should see statistics and verification requests
   - ❌ If "Access Denied" appears, check the role in database

---

## 🔧 Troubleshooting

### Issue: "Invalid email or password"
**Cause**: Wrong credentials or user doesn't exist  
**Solution**: 
- Verify email spelling in both Auth and users table
- Try resetting password in Authentication → Users → (select user) → Reset Password

### Issue: "Access Denied - You do not have verifier permissions"
**Cause**: User exists but role is not 'VERIFIER'  
**Solution**:
```sql
-- Check current role
SELECT id, email, role FROM users WHERE email = 'verifier@pasabay.com';

-- Update to VERIFIER if incorrect
UPDATE users 
SET role = 'VERIFIER'
WHERE email = 'verifier@pasabay.com';
```

### Issue: "Error getting user role: Cannot coerce result to single JSON object"
**Cause**: User exists in auth.users but NOT in users table  
**Solution**: Run the INSERT query from Step 2 above

### Issue: "users_role_check constraint violation"
**Cause**: Trying to insert invalid role value  
**Solution**: Ensure role is exactly `'VERIFIER'` (all caps, as string)

---

## 👥 Creating Multiple Verifiers

To create multiple verifier accounts, repeat the process for each:

```sql
-- Verifier 1
INSERT INTO users (id, email, role, full_name)
VALUES ('USER_ID_1', 'verifier1@pasabay.com', 'VERIFIER', 'First Verifier');

-- Verifier 2
INSERT INTO users (id, email, role, full_name)
VALUES ('USER_ID_2', 'verifier2@pasabay.com', 'VERIFIER', 'Second Verifier');

-- Verifier 3
INSERT INTO users (id, email, role, full_name)
VALUES ('USER_ID_3', 'verifier3@pasabay.com', 'VERIFIER', 'Third Verifier');
```

---

## 🎯 Recommended Verifier Credentials Format

When creating verifiers, use this format for better organization:

| Field | Format | Example |
|-------|--------|---------|
| Email | verifier{number}@pasabay.com | verifier1@pasabay.com |
| Full Name | Verifier {Name} | Verifier John |
| Password | Min 12 chars, mixed case + numbers | SecurePass123! |
| Role | VERIFIER (all caps) | VERIFIER |

---

## 🔐 Security Best Practices

1. **Use strong passwords** - At least 12 characters with mixed case, numbers, symbols
2. **Keep credentials secure** - Use password managers
3. **Regular audits** - Review verifier list monthly
4. **Revoke access** when verifiers leave:
   ```sql
   -- Disable verifier
   UPDATE users SET role = 'TRAVELER' WHERE email = 'old-verifier@pasabay.com';
   
   -- Or delete entirely
   DELETE FROM auth.users WHERE email = 'old-verifier@pasabay.com';
   ```
5. **Monitor activity** - Check verification logs regularly

---

## 📞 Support

If you need help creating verifier accounts:
- Check Supabase Dashboard permissions
- Verify database migrations are applied
- Ensure RLS policies allow reading user roles
- Contact project administrator

---

**Current Verifier App URLs:**
- Development: http://localhost:8082
- Production: [Your deployed URL]

**Main User App URLs:**
- Development: http://localhost:8080
- Production: [Your deployed URL]
