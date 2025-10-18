# Identity Verification Feature

## Overview
The Identity Verification screen is displayed to travelers after they select their role. This ensures platform safety by requiring travelers to verify their identity before they can book travel services.

## User Flow
1. User signs up → Verifies email with 6-digit OTP
2. User selects "Traveler" role on Role Selection page
3. **Identity Verification screen is shown**
4. User can either:
   - Click "Start Verification" → Upload documents (coming soon)
   - Click "Verify Later" → Skip to Traveler Home (limited features)

## Implementation Status

### ✅ Completed
- **UI Design**: Fully implemented based on Figma design (node 205-560)
- **Navigation**: Integrated with Role Selection page
- **Layout**: Responsive wrapper with proper spacing
- **Components**: All UI elements match design specs

### 🚧 In Progress
- Document upload functionality
- Supabase Storage integration
- Admin verification review interface

### ⏳ Pending
- Image picker integration
- Document validation
- Face matching
- OCR for ID verification

## File Structure

```
lib/
├── screens/
│   ├── traveler/
│   │   └── identity_verification_screen.dart  ← New screen
│   └── role_selection_page.dart  ← Updated to navigate to verification
└── main.dart  ← Added route for identity verification
```

## Design Specs

### Colors
- Primary Blue: `#00AAF3`
- Background: `#F9F9F9`
- Text Dark: `#101828`
- Text Light: `#4A5565`
- Security Notice BG: `#DBEBFF`
- Card BG: `#FFFFFF`

### Typography
- Title: Lexend Bold, 48px, line-height 51.9px
- Heading: Inter Bold, 16.689px
- Body: Inter Regular, 14.305px

### Layout
- Container padding: 28px horizontal
- Card spacing: 14px vertical
- Card border radius: 16.689px
- Button height: 57.22px

## Required Documents

### 1. Government-issued Valid ID
Valid options:
- National ID
- Driver's License
- Passport
- UMID
- Other government-issued IDs

**Requirements:**
- Clear photo of ID
- All text readable
- Not expired
- Front and back (if applicable)

### 2. Selfie Photo
**Requirements:**
- Face clearly visible
- Good lighting
- No filters/edits
- Match ID photo for verification

## Security Features

### Data Protection
- All documents encrypted at rest
- Secure upload via HTTPS
- Access restricted with RLS policies
- Documents only accessible by user and admins

### Privacy
- Documents used only for verification
- Not shared with third parties
- Automatically deleted after verification (configurable)
- User can request data deletion

## Next Steps

### 1. Create Document Upload Service
Create `lib/services/verification_service.dart`:
```dart
class VerificationService {
  Future<String> uploadDocument(File file, String documentType);
  Future<void> submitVerification(Map<String, String> documentUrls);
  Future<VerificationStatus> checkStatus();
}
```

### 2. Set Up Supabase Storage
```sql
-- Create storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('verification-documents', 'verification-documents', false);

-- RLS Policy: Users can upload their own documents
CREATE POLICY "Users can upload verification documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'verification-documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS Policy: Users can view their own documents
CREATE POLICY "Users can view their verification documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'verification-documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

### 3. Create Database Schema
```sql
-- Verification requests table
CREATE TABLE verification_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  id_type VARCHAR(50) NOT NULL, -- 'passport', 'national_id', 'drivers_license', etc.
  id_front_url TEXT NOT NULL,
  id_back_url TEXT, -- Optional for some ID types
  selfie_url TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'resubmit'
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add is_verified to users table
ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;

-- Index for faster queries
CREATE INDEX idx_verification_requests_user_id ON verification_requests(user_id);
CREATE INDEX idx_verification_requests_status ON verification_requests(status);
```

### 4. Install Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  image_picker: ^1.0.5  # For taking photos
  permission_handler: ^11.1.0  # For camera permissions
  image_cropper: ^5.0.1  # For cropping uploaded images
```

### 5. Implement Document Upload UI
Create `lib/screens/traveler/document_upload_screen.dart`:
- ID type selector (dropdown)
- Camera/gallery picker for ID front
- Camera/gallery picker for ID back (conditional)
- Camera/gallery picker for selfie
- Preview uploaded images
- Submit button

### 6. Admin Verification Review
Create `lib/screens/admin/verification_review_screen.dart`:
- List pending verifications
- View submitted documents side-by-side
- Approve/Reject/Request Resubmission
- Add rejection reason

## Testing Checklist

### User Flow Testing
- [ ] User selects "Traveler" role → Sees verification screen
- [ ] "Verify Later" navigates to Traveler Home
- [ ] "Start Verification" shows coming soon message
- [ ] Back button works correctly
- [ ] UI matches Figma design exactly

### After Upload Implementation
- [ ] Can select ID type
- [ ] Can take photo with camera
- [ ] Can upload from gallery
- [ ] Images preview correctly
- [ ] Can crop/rotate images
- [ ] Upload progress shows
- [ ] Success/error messages display
- [ ] Documents appear in Supabase Storage
- [ ] Database record created correctly

### Admin Review Testing
- [ ] Admin sees pending verifications
- [ ] Can view all submitted documents
- [ ] Can approve verification
- [ ] Can reject with reason
- [ ] User receives notification
- [ ] Verification status updates correctly

## API Integration

### SupabaseService Methods to Add
```dart
// In lib/utils/supabase_service.dart

Future<void> submitVerification({
  required String idType,
  required String idFrontUrl,
  String? idBackUrl,
  required String selfieUrl,
}) async {
  await supabase.from('verification_requests').insert({
    'user_id': currentUser!.id,
    'id_type': idType,
    'id_front_url': idFrontUrl,
    'id_back_url': idBackUrl,
    'selfie_url': selfieUrl,
    'status': 'pending',
  });
}

Future<Map<String, dynamic>?> getVerificationStatus() async {
  final response = await supabase
    .from('verification_requests')
    .select()
    .eq('user_id', currentUser!.id)
    .order('created_at', ascending: false)
    .limit(1)
    .maybeSingle();
  
  return response;
}

Future<bool> isUserVerified() async {
  final userData = await supabase
    .from('users')
    .select('is_verified')
    .eq('id', currentUser!.id)
    .single();
  
  return userData['is_verified'] ?? false;
}
```

## Notes
- Always check verification status on app launch
- Show verification reminder if status is 'pending' or 'rejected'
- Restrict certain features until verified (e.g., booking services)
- Send email notification when verification is approved/rejected
