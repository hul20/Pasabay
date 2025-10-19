# Identity Verification - File Upload Implementation

## 🎯 Overview
This document explains how to connect the uploaded Government ID and Selfie files to Supabase Storage and database.

## ✅ What's Been Implemented

### 1. Supabase Service Methods (`supabase_service.dart`)

Added three new methods for file upload:

```dart
/// Upload Government ID document (returns public URL)
Future<String> uploadGovernmentId(Uint8List fileBytes, String fileName)

/// Upload Selfie photo (returns public URL)
Future<String> uploadSelfie(Uint8List fileBytes, String fileName)

/// Submit verification request with both file URLs
Future<void> submitVerificationRequest({
  required String govIdUrl,
  required String selfieUrl,
  required String govIdFileName,
  required String selfieFileName,
})
```

---

## 🔧 Step 1: Create Supabase Storage Bucket (REQUIRED!)

Before files can be uploaded, you need to create a storage bucket in Supabase.

### Go to Supabase Dashboard
1. Open: https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv
2. Click **Storage** in the left sidebar
3. Click **New bucket**
4. Enter bucket details:
   - **Name**: `verification-documents`
   - **Public bucket**: ✅ **YES** (check this box)
   - **File size limit**: 50 MB
   - **Allowed MIME types**: Leave empty (allows all)
5. Click **Create bucket**

### Set Storage Policies (Security)

After creating the bucket, set up Row Level Security policies:

1. Click on the `verification-documents` bucket
2. Click **Policies** tab
3. Click **New policy**
4. Create policy for **INSERT** (Upload):
   - **Policy name**: `Users can upload own verification documents`
   - **Allowed operation**: INSERT
   - **Target roles**: authenticated
   - **USING expression**:
   ```sql
   (bucket_id = 'verification-documents'::text) AND 
   ((storage.foldername(name))[1] = auth.uid()::text)
   ```
5. Create policy for **SELECT** (View):
   - **Policy name**: `Users can view own verification documents`
   - **Allowed operation**: SELECT
   - **Target roles**: authenticated
   - **USING expression**:
   ```sql
   (bucket_id = 'verification-documents'::text) AND 
   ((storage.foldername(name))[1] = auth.uid()::text)
   ```

---

## 🔧 Step 2: Update Database Schema

Update the `verification_requests` table to include file URLs:

Go to: https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/sql

Run this SQL:

```sql
-- Add columns for file URLs and filenames
ALTER TABLE public.verification_requests 
ADD COLUMN IF NOT EXISTS gov_id_url TEXT,
ADD COLUMN IF NOT EXISTS selfie_url TEXT,
ADD COLUMN IF NOT EXISTS gov_id_filename TEXT,
ADD COLUMN IF NOT EXISTS selfie_filename TEXT,
ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS verification_requests_gov_id_url_idx 
ON public.verification_requests(gov_id_url);

CREATE INDEX IF NOT EXISTS verification_requests_selfie_url_idx 
ON public.verification_requests(selfie_url);
```

---

## 📝 Step 3: Update Review Documents Screen

Now update `review_documents_screen.dart` to actually upload files when submitting:

### Current Code (Mock/Test Mode)
```dart
Future<void> _submitForVerification() async {
  setState(() => _isSubmitting = true);
  
  // Mock 2-second delay
  await Future.delayed(const Duration(seconds: 2));
  
  // Navigate to success screen
  Navigator.pushAndRemoveUntil(...);
}
```

### Production Code (With Upload)
```dart
Future<void> _submitForVerification() async {
  setState(() => _isSubmitting = true);
  
  try {
    final supabaseService = SupabaseService();
    
    // TODO: Get file bytes from stored files
    // You'll need to pass these from previous screens
    Uint8List govIdBytes = ...; // From Step 1
    Uint8List selfieBytes = ...; // From Step 2
    String govIdFileName = ...; // From Step 1
    String selfieFileName = ...; // From Step 2
    
    // Upload Government ID
    String govIdUrl = await supabaseService.uploadGovernmentId(
      govIdBytes,
      govIdFileName,
    );
    
    // Upload Selfie
    String selfieUrl = await supabaseService.uploadSelfie(
      selfieBytes,
      selfieFileName,
    );
    
    // Submit verification request
    await supabaseService.submitVerificationRequest(
      govIdUrl: govIdUrl,
      selfieUrl: selfieUrl,
      govIdFileName: govIdFileName,
      selfieFileName: selfieFileName,
    );
    
    if (!mounted) return;
    
    // Navigate to success screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const VerificationSuccessfulScreen(),
      ),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
```

---

## 📂 Step 4: Store File Data Between Screens

You need to pass file data from Step 1 and Step 2 to the Review Documents screen.

### Option 1: Pass via Navigation (Recommended for now)

**Update `gov_id_upload_screen.dart`:**
```dart
// After file picked
FilePickerResult? result = await FilePicker.platform.pickFiles(...);
if (result != null) {
  Uint8List? fileBytes = result.files.first.bytes;
  String fileName = result.files.first.name;
  
  // Navigate to Step 2 with file data
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SelfieUploadScreen(
        govIdBytes: fileBytes!,
        govIdFileName: fileName,
      ),
    ),
  );
}
```

**Update `selfie_upload_screen.dart`:**
```dart
class SelfieUploadScreen extends StatefulWidget {
  final Uint8List govIdBytes;
  final String govIdFileName;
  
  const SelfieUploadScreen({
    required this.govIdBytes,
    required this.govIdFileName,
    super.key,
  });
  
  @override
  State<SelfieUploadScreen> createState() => _SelfieUploadScreenState();
}

// After selfie captured
XFile? photo = await _picker.pickImage(...);
if (photo != null) {
  Uint8List photoBytes = await photo.readAsBytes();
  
  // Navigate to Review with both files
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReviewDocumentsScreen(
        govIdBytes: widget.govIdBytes,
        govIdFileName: widget.govIdFileName,
        selfieBytes: photoBytes,
        selfieFileName: photo.name,
      ),
    ),
  );
}
```

**Update `review_documents_screen.dart`:**
```dart
class ReviewDocumentsScreen extends StatefulWidget {
  final Uint8List govIdBytes;
  final String govIdFileName;
  final Uint8List selfieBytes;
  final String selfieFileName;
  
  const ReviewDocumentsScreen({
    required this.govIdBytes,
    required this.govIdFileName,
    required this.selfieBytes,
    required this.selfieFileName,
    super.key,
  });
  
  @override
  State<ReviewDocumentsScreen> createState() => _ReviewDocumentsScreenState();
}

// Now you can use widget.govIdBytes, widget.selfieBytes, etc.
```

### Option 2: Use State Management (GetX, Provider, Riverpod)

For a cleaner approach in larger apps, use state management to store file data globally.

---

## 🧪 Testing the Implementation

### Test File Upload Flow:

1. **Step 1**: Upload Government ID
   - File is selected and bytes are stored
   - Navigate to Step 2 with file data
   
2. **Step 2**: Capture Selfie
   - Photo is taken and bytes are stored
   - Navigate to Step 3 with both files
   
3. **Step 3**: Review Documents
   - Show filenames/previews
   - On "Submit", upload both files to Supabase
   - Wait for uploads to complete
   - Submit verification request to database
   - Navigate to success screen

### Verify in Supabase Dashboard:

1. **Check Storage**:
   - Go to Storage → verification-documents
   - Should see folders with user IDs
   - Inside: `gov_id_*.jpg` and `selfie_*.jpg`

2. **Check Database**:
   - Go to Table Editor → verification_requests
   - Should see new row with:
     - `gov_id_url`: Full Supabase Storage URL
     - `selfie_url`: Full Supabase Storage URL
     - `status`: 'pending'
     - File names and timestamps

---

## 📁 File Storage Structure

Files are organized by user ID in Supabase Storage:

```
verification-documents/
├── {user-id-1}/
│   ├── gov_id_1729387654321.jpg
│   └── selfie_1729387665432.jpg
├── {user-id-2}/
│   ├── gov_id_1729387698765.pdf
│   └── selfie_1729387712345.jpg
└── {user-id-3}/
    ├── gov_id_1729387734567.png
    └── selfie_1729387745678.jpg
```

**Benefits:**
- ✅ User isolation (each user has own folder)
- ✅ Unique filenames (timestamp prevents conflicts)
- ✅ Easy to find files for specific user
- ✅ Row Level Security prevents access to other users' files

---

## 🔒 Security Features

1. **Folder-based isolation**: Files are stored in `{user_id}/` folders
2. **RLS Policies**: Users can only upload/view their own files
3. **Authentication**: Must be logged in to upload
4. **File validation**: Client-side checks for file type and size

---

## ⚠️ Important Notes

### File Size Limits
- **Default**: 50 MB per file
- Adjust in bucket settings if needed
- Consider compressing images before upload

### File Types
Currently accepts:
- **Gov ID**: .jpg, .jpeg, .png, .pdf
- **Selfie**: .jpg, .jpeg, .png

### Error Handling
Always handle these errors:
- Network errors (slow/no connection)
- Storage quota exceeded
- Invalid file format
- Authentication expired

---

## 🎯 Next Steps

1. ✅ **Create Supabase Storage bucket** (Step 1)
2. ✅ **Update database schema** (Step 2)
3. ⏳ **Update screens to pass file bytes** (Step 4)
4. ⏳ **Replace mock upload with real upload** (Step 3)
5. ⏳ **Test complete flow**
6. ⏳ **Build admin review interface**

---

## 📚 References

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Flutter File Picker](https://pub.dev/packages/file_picker)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)

---

**Status**: Implementation ready, needs Supabase configuration and screen updates ✅
