# 🔧 Fix: Cannot Accept Requests as Traveler

## 🐛 Error

```
Error accepting request: PostgrestException(
  message: column "accepted_requests" does not exist, 
  code: 42703
)
```

---

## 🔍 Root Cause

### **The Problem:**

The `accept_service_request()` SQL function tries to update a column that doesn't exist!

**What the function tries to do:**
```sql
UPDATE public.trips
SET available_capacity = available_capacity - 1,
    accepted_requests = accepted_requests + 1    -- ❌ This column doesn't exist!
WHERE id = v_trip_id;
```

**What the trips table actually has:**
```sql
CREATE TABLE trips (
  available_capacity INTEGER,
  current_requests INTEGER,     -- ✅ This is the correct column name!
  ...
)
```

---

## ✅ The Fix

### **Run in Supabase SQL Editor:**

Copy the entire contents of `fix_accept_request_function.sql` and run it in Supabase.

**OR run this SQL:**

```sql
-- Fix: Accept Service Request Function
CREATE OR REPLACE FUNCTION public.accept_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_current_capacity INTEGER;
    v_traveler_id UUID;
BEGIN
    -- Get trip_id and traveler_id from the request
    SELECT trip_id, traveler_id INTO v_trip_id, v_traveler_id
    FROM public.service_requests
    WHERE id = request_id AND status = 'Pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if there's available capacity
    SELECT available_capacity INTO v_current_capacity
    FROM public.trips
    WHERE id = v_trip_id;
    
    IF v_current_capacity <= 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Accept the request
    UPDATE public.service_requests
    SET status = 'Accepted', updated_at = NOW()
    WHERE id = request_id;
    
    -- Update trip capacity (FIXED: use current_requests)
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        current_requests = current_requests + 1,     -- ✅ FIXED
        updated_at = NOW()
    WHERE id = v_trip_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the cancel function
CREATE OR REPLACE FUNCTION public.cancel_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_requester_id UUID;
    v_current_status VARCHAR(20);
BEGIN
    -- Get request details
    SELECT trip_id, requester_id, status 
    INTO v_trip_id, v_requester_id, v_current_status
    FROM public.service_requests
    WHERE id = request_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if the current user is the requester
    IF auth.uid() != v_requester_id THEN
        RETURN FALSE;
    END IF;
    
    -- Can only cancel Pending or Accepted requests
    IF v_current_status NOT IN ('Pending', 'Accepted') THEN
        RETURN FALSE;
    END IF;
    
    -- If it was accepted, restore capacity (FIXED: use current_requests)
    IF v_current_status = 'Accepted' THEN
        UPDATE public.trips
        SET available_capacity = available_capacity + 1,
            current_requests = current_requests - 1,     -- ✅ FIXED
            updated_at = NOW()
        WHERE id = v_trip_id;
    END IF;
    
    -- Cancel the request
    UPDATE public.service_requests
    SET status = 'Cancelled', updated_at = NOW()
    WHERE id = request_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📍 How to Apply

### **Step 1: Open Supabase Dashboard**
1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your project

### **Step 2: Open SQL Editor**
1. Click "SQL Editor" in sidebar
2. Click "New Query"

### **Step 3: Run the Fix**
1. Copy the SQL above (or from `fix_accept_request_function.sql`)
2. Paste into SQL Editor
3. Click "Run"
4. Should see "Success" ✅

### **Step 4: Test**
1. No need to rebuild Flutter app!
2. Just test accepting a request as a traveler
3. Should work immediately ✅

---

## 🧪 Testing

### **Test Flow:**
1. **As Requester:**
   - Submit a Pasabay or Pabakal request
   
2. **As Traveler:**
   - Go to Activity tab
   - Select your registered schedule
   - Go to "Requests" tab
   - Tap on a pending request
   - Click "Accept Request"
   - **Expected:** ✅ Success! Request accepted

### **Console Output (After Fix):**
```
✅ Request accepted successfully!
Request moved to "Ongoing" tab
```

---

## 📊 What Changes

### **Before (Broken):**
```sql
UPDATE trips
SET accepted_requests = accepted_requests + 1    -- ❌ Column doesn't exist
```
**Result:** Error!

### **After (Fixed):**
```sql
UPDATE trips
SET current_requests = current_requests + 1      -- ✅ Correct column
```
**Result:** Works! ✅

---

## 📋 Column Reference

### **trips Table Columns:**
- `available_capacity` - Remaining slots for requests
- `current_requests` - Number of accepted requests (counts toward capacity)

### **How It Works:**
```
Initial State:
- available_capacity: 5
- current_requests: 0

After accepting 1 request:
- available_capacity: 4  (decremented)
- current_requests: 1    (incremented)

After accepting 5 requests:
- available_capacity: 0  (full!)
- current_requests: 5    (max reached)
```

---

## ✅ All SQL Fixes Needed

### **Fix #1: Users RLS Policy** (for traveler names)
```sql
-- Run: fix_users_rls_policy.sql
CREATE POLICY "Users can view all profiles" ON users
  FOR SELECT TO authenticated USING (true);
```

### **Fix #2: Accept Request Function** (this fix)
```sql
-- Run: fix_accept_request_function.sql
-- Changes accepted_requests → current_requests
```

### **Fix #3: Realtime Setup** (for chat)
```sql
-- Run: supabase_realtime_setup.sql
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER TABLE messages REPLICA IDENTITY FULL;
```

---

## 🚀 Quick Summary

**Problem:** SQL function uses wrong column name
**Fix:** Update function to use correct column name
**Where:** Supabase SQL Editor
**Impact:** Travelers can now accept requests! ✅

---

## ⚡ Quick Fix Command

**Just run this in Supabase:**

```sql
-- Quick fix (copy-paste this)
CREATE OR REPLACE FUNCTION public.accept_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_current_capacity INTEGER;
    v_traveler_id UUID;
BEGIN
    SELECT trip_id, traveler_id INTO v_trip_id, v_traveler_id
    FROM public.service_requests
    WHERE id = request_id AND status = 'Pending';
    
    IF NOT FOUND THEN RETURN FALSE; END IF;
    
    SELECT available_capacity INTO v_current_capacity
    FROM public.trips WHERE id = v_trip_id;
    
    IF v_current_capacity <= 0 THEN RETURN FALSE; END IF;
    
    UPDATE public.service_requests
    SET status = 'Accepted', updated_at = NOW()
    WHERE id = request_id;
    
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        current_requests = current_requests + 1,
        updated_at = NOW()
    WHERE id = v_trip_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Done! No Flutter changes needed!** ✅

---

**Go to Supabase and run the fix now!** 🚀

