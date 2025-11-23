# ⚡ Quick Fix: Traveler Name "null null" Issue

## 🎯 Problem
Traveler names show as "null null" for other users (not yourself).

## 🔧 Root Cause
RLS policy on `users` table only allows viewing own profile.

## ✅ Solution
Run this in Supabase SQL Editor:

```sql
DROP POLICY IF EXISTS "Users can view their own profile" ON users;

CREATE POLICY "Users can view all profiles" ON users
  FOR SELECT
  TO authenticated
  USING (true);
```

## 📋 Steps
1. Open [Supabase Dashboard](https://app.supabase.com)
2. Go to SQL Editor
3. Paste the SQL above
4. Click "Run"
5. Done! ✅

## 🧪 Test
1. Restart Flutter app
2. Login as requester
3. Search for travelers
4. Should see actual names! ✅

## 📖 Full Guide
See `FIX_TRAVELER_NAME_RLS_ISSUE.md` for details.

---

**That's it! No code changes needed!** 🚀

