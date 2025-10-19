# 🔧 Fix: "Could not find gov_id_filename column" Error

## The Problem
The `verification_requests` table exists but doesn't have the file URL columns (`gov_id_url`, `selfie_url`, `gov_id_filename`, `selfie_filename`).

## Quick Fix

### Option 1: Add Missing Columns (If you want to keep existing data)

Run this SQL in Supabase SQL Editor:

```sql
-- Add missing columns to existing table
ALTER TABLE public.verification_requests 
ADD COLUMN IF NOT EXISTS gov_id_url TEXT,
ADD COLUMN IF NOT EXISTS selfie_url TEXT,
ADD COLUMN IF NOT EXISTS gov_id_filename TEXT,
ADD COLUMN IF NOT EXISTS selfie_filename TEXT,
ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;

-- Add indexes
CREATE INDEX IF NOT EXISTS verification_requests_gov_id_url_idx 
ON public.verification_requests(gov_id_url);

CREATE INDEX IF NOT EXISTS verification_requests_selfie_url_idx 
ON public.verification_requests(selfie_url);

-- Add comments
COMMENT ON COLUMN public.verification_requests.gov_id_url IS 'Supabase Storage URL for government ID document';
COMMENT ON COLUMN public.verification_requests.selfie_url IS 'Supabase Storage URL for selfie photo';
COMMENT ON COLUMN public.verification_requests.gov_id_filename IS 'Original filename of government ID';
COMMENT ON COLUMN public.verification_requests.selfie_filename IS 'Original filename of selfie';
COMMENT ON COLUMN public.verification_requests.submitted_at IS 'When user submitted the verification request';
```

### Option 2: Recreate Table (If you don't have important data)

1. Go to Supabase Dashboard → SQL Editor
2. Open: `migrations/COMPLETE_setup_verification_table.sql`
3. Copy all the SQL
4. Paste in SQL Editor
5. Click **RUN**

This will create the table with ALL required columns.

## Steps to Fix:

### 1. Go to Supabase Dashboard
```
https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql
```

### 2. Open SQL Editor
- Click "SQL Editor" in left sidebar
- Click "+ New query"

### 3. Choose Your Option

**Option A - Quick Fix (Add Columns)**
```sql
ALTER TABLE public.verification_requests 
ADD COLUMN IF NOT EXISTS gov_id_url TEXT,
ADD COLUMN IF NOT EXISTS selfie_url TEXT,
ADD COLUMN IF NOT EXISTS gov_id_filename TEXT,
ADD COLUMN IF NOT EXISTS selfie_filename TEXT,
ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;
```

**Option B - Complete Setup (Recreate)**
- Copy contents of `migrations/COMPLETE_setup_verification_table.sql`
- Paste in SQL Editor
- Run

### 4. Verify the Fix

Run this query to check columns:
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'verification_requests'
ORDER BY ordinal_position;
```

You should see:
- ✅ gov_id_url (text)
- ✅ selfie_url (text)
- ✅ gov_id_filename (text)
- ✅ selfie_filename (text)
- ✅ submitted_at (timestamp with time zone)

### 5. Test Again

After running the SQL:
1. Restart your Flutter app
2. Go through verification flow
3. Upload Government ID
4. Upload Selfie
5. Submit for verification
6. Should work now! ✅

## Why This Happened

The original SQL script (`create_verification_requests_table.sql`) created the table without the file URL columns. You needed to run BOTH scripts:
1. `create_verification_requests_table.sql` (creates basic table)
2. `add_verification_file_urls.sql` (adds file columns)

The new `COMPLETE_setup_verification_table.sql` includes everything in one file.

## Expected Result

After fixing, submission should work and you'll see:
- ✅ Success message
- ✅ Navigation to success screen
- ✅ Record in `verification_requests` table with file URLs

## Need Help?

If still having issues:
1. Check Supabase Logs (Dashboard → Logs)
2. Make sure user is authenticated
3. Verify RLS policies are set
4. Check Storage bucket exists

---

**Quick Command:**
```sql
-- Copy and paste this in SQL Editor:
ALTER TABLE public.verification_requests 
ADD COLUMN IF NOT EXISTS gov_id_url TEXT,
ADD COLUMN IF NOT EXISTS selfie_url TEXT,
ADD COLUMN IF NOT EXISTS gov_id_filename TEXT,
ADD COLUMN IF NOT EXISTS selfie_filename TEXT,
ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;
```

Then click **RUN** and test again! ✅
