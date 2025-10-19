# Quick Test Guide - File Upload

## Before Testing

### 1. Create Storage Bucket
1. Go to Supabase Dashboard → Storage
2. Click "Create a new bucket"
3. Name: `verification-documents`
4. Make it Public
5. Click "Create bucket"

### 2. Set Storage Policies
1. Click on the bucket → Policies tab
2. Click "New Policy" → Custom
3. Copy-paste these two policies:

**Upload Policy:**
```sql
CREATE POLICY "Users can upload their files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'verification-documents'
);
```

**Read Policy:**
```sql
CREATE POLICY "Users can read files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'verification-documents'
);
```

### 3. Create Database Table
1. Go to SQL Editor
2. Copy-paste the SQL from `migrations/create_verification_requests_table.sql`
3. Click "RUN"
4. You should see: "Success. No rows returned"

## Testing the Flow

### Step 1: Government ID Upload
1. ✅ Navigate to Identity Verification
2. ✅ Click "Upload Your Government ID"
3. ✅ Click "Choose File" button
4. ✅ Select a PDF or image (jpg, png)
5. ✅ **Watch for**:
   - Loading spinner with "Uploading..." message
   - Success message: "Government ID uploaded successfully!"
   - Checkmark icon appears
   - Button changes to "Change File"
   - File name displays
6. ✅ Click "Continue"

### Step 2: Selfie Upload
1. ✅ Click "Take A Photo" OR "Upload"
2. ✅ If using camera:
   - Allow camera permissions
   - Take a photo
   - Watch for upload
3. ✅ If using upload:
   - Select an image from gallery
   - Watch for upload
4. ✅ **Watch for**:
   - Loading spinner during upload
   - Success message
   - Image displays in preview
   - Green checkmark appears
5. ✅ Click "Continue"

### Step 3: Review & Submit
1. ✅ Verify both files are listed
2. ✅ Click "Submit for Verification"
3. ✅ **Watch for**:
   - Loading button state
   - Success message
   - Navigation to success screen

### Verify in Supabase

#### Check Storage:
1. Go to Storage → verification-documents
2. You should see a folder with your user UUID
3. Inside: `gov_id_[timestamp].pdf` and `selfie_[timestamp].jpg`

#### Check Database:
1. Go to Table Editor → verification_requests
2. You should see a new row with:
   - Your user_id
   - Both file URLs
   - Both filenames
   - status: 'pending'
   - submitted_at: current time

## Common Issues & Solutions

### ❌ "User not authenticated"
**Solution**: Make sure you're logged in before testing

### ❌ "Bucket does not exist"
**Solution**: Create the `verification-documents` bucket in Supabase Storage

### ❌ "Permission denied"
**Solution**: Add the RLS policies for storage access

### ❌ "relation does not exist"
**Solution**: Run the SQL script to create verification_requests table

### ❌ Camera not working on web
**Solution**: 
- Use Upload button instead of Take A Photo
- Or test on mobile device
- Camera requires HTTPS in production

### ❌ File picker not opening
**Solution**: Check browser permissions for file access

## Expected Behavior

### Loading States
- ✅ Buttons disabled during upload
- ✅ Spinner shows "Uploading..."
- ✅ Cannot click continue until complete

### Success States
- ✅ Green success messages
- ✅ Checkmark icons
- ✅ File previews/names display
- ✅ Can change/reupload files

### Error States
- ✅ Red error messages
- ✅ Can retry upload
- ✅ Form stays on current screen

## Quick Commands

### Check if table exists:
```sql
SELECT * FROM verification_requests;
```

### View your uploads:
```sql
SELECT * FROM verification_requests 
WHERE user_id = auth.uid();
```

### Check storage bucket:
```sql
SELECT * FROM storage.objects 
WHERE bucket_id = 'verification-documents';
```

### Delete test data:
```sql
-- Delete from database
DELETE FROM verification_requests WHERE user_id = auth.uid();

-- Delete from storage (do this in Storage UI, or via SQL):
DELETE FROM storage.objects 
WHERE bucket_id = 'verification-documents' 
AND (storage.foldername(name))[1] = auth.uid()::text;
```

## What to Test

### Functional Testing
- [ ] Upload PDF for Government ID
- [ ] Upload JPG for Government ID
- [ ] Upload PNG for Government ID
- [ ] Take photo with camera for selfie
- [ ] Upload image from gallery for selfie
- [ ] Try continuing without uploading (should show error)
- [ ] Upload, then change file
- [ ] Complete full flow from Step 1 to Success

### UI Testing
- [ ] Loading spinners appear
- [ ] Success messages show
- [ ] File names display correctly
- [ ] Images preview correctly
- [ ] Buttons enable/disable properly
- [ ] Progress dots update correctly
- [ ] Gradient header displays correctly
- [ ] Responsive on mobile and web

### Error Testing
- [ ] Test with no internet (should show error)
- [ ] Test with invalid file (should reject)
- [ ] Test logging out mid-upload
- [ ] Test navigating back during upload

## Debug Mode

If you want to see upload progress in console:

```dart
// Add this to the upload methods in supabase_service.dart
print('Uploading to: $storagePath');
print('File size: ${fileBytes.length} bytes');
print('Public URL: $publicUrl');
```

## Success Checklist

When testing is successful, you should have:
- ✅ Files in Supabase Storage bucket
- ✅ Record in verification_requests table
- ✅ All URLs working (clickable in database)
- ✅ User on success screen
- ✅ No errors in console

---

**Happy Testing! 🚀**

If you encounter issues not covered here, check:
1. Browser console for errors
2. Supabase Dashboard → Logs
3. Network tab for failed requests
