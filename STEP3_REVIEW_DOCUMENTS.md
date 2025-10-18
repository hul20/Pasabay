# Step 3: Review Documents Screen - Implementation Guide

## Overview
The Review Documents screen is the final step (Step 3) in the identity verification process. It allows users to review their uploaded Government ID and Selfie photo before submitting for verification.

## Design Reference
- **Figma Node**: `228-5232`
- **Screen Name**: Step 3 - Review
- **Purpose**: Review and submit identity verification documents

## Features

### 1. Visual Design
- **Gradient Header**: Cyan gradient background (#37BFF9 to #00AAF3)
- **Heading**: "Review Your Documents"
- **Progress Indicator**: 3-step circular progress with Steps 1 & 2 completed (checkmarks), Step 3 active

### 2. Document Cards
Two document review cards showing:

#### Government ID Card
- Icon: Credit card icon in light blue background
- Title: "Government ID"
- Filename: Shows uploaded file name
- Status: Green checkmark (uploaded successfully)
- Action: "View" button (blue)

#### Selfie Photo Card
- Icon: Camera icon in light blue background
- Title: "Selfie Photo"
- Filename: Shows uploaded file name
- Status: Green checkmark (uploaded successfully)
- Action: "View" button (blue)

### 3. Information Box
- **Background**: Light blue (Colors.blue.shade50)
- **Icon**: Info outline icon
- **Title**: "Before You Submit"
- **Message**: "Please ensure all documents are clear and readable. Our verification team will review your submission within 24-48 hours."

### 4. Action Buttons
- **Submit For Verification**: Primary blue button
  - Disabled state with loading indicator during submission
  - Full width with rounded corners
- **Back**: Secondary white button
  - Returns to previous screen (Selfie Upload)

## File Structure

### Main File
```
lib/screens/traveler/review_documents_screen.dart
```

### Parameters
```dart
final File? governmentIdFile;
final File? selfieFile;
final String? governmentIdFileName;
final String? selfieFileName;
```

## Navigation Flow

### From Previous Screen
```dart
// In selfie_upload_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ReviewDocumentsScreen(
      governmentIdFile: widget.governmentIdFile,
      selfieFile: _selectedImage,
      governmentIdFileName: widget.governmentIdFileName,
      selfieFileName: _selectedImage?.path.split('/').last,
    ),
  ),
);
```

### After Submission
After successful submission, the screen:
1. Shows success SnackBar message
2. Returns to root route (landing page)

TODO: Replace with navigation to "Under Review" status screen or Traveler Home

## Key Functions

### _submitForVerification()
Handles the document submission process:

**Current Implementation** (Testing Mode):
```dart
// Simulate upload delay
await Future.delayed(const Duration(seconds: 2));

// Show success message
ScaffoldMessenger.of(context).showSnackBar(...);

// Navigate back to root
Navigator.of(context).popUntil((route) => route.isFirst);
```

**TODO for Production**:
1. Upload Government ID to Supabase Storage
2. Upload Selfie to Supabase Storage
3. Create verification request record in database
4. Update user's `is_verified` status to 'pending'
5. Send notification to admins
6. Send email confirmation to user
7. Navigate to appropriate screen

### _viewDocument(String documentType)
Opens a full-screen viewer for the selected document.

**Current Implementation**: Shows SnackBar message

**TODO**: Implement full-screen image viewer using packages like:
- `photo_view`
- `flutter_image_preview`

## Progress Indicator

### Visual States
- **Step 1**: Completed (checkmark on cyan circle)
- **Step 2**: Completed (checkmark on cyan circle)
- **Step 3**: Active (white circle with blue border)

### Implementation
```dart
Widget _buildProgressIndicator(double scaleFactor) {
  // Step 1 & 2: Checkmark icons with completed colors
  // Step 3: White circle with blue border (active)
}
```

## Responsive Design

### Scale Factor
Uses `ResponsiveHelper.getScaleFactor(screenWidth)` to scale all dimensions.

### Layout
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final scaleFactor = ResponsiveHelper.getScaleFactor(constraints.maxWidth);
    // All dimensions multiplied by scaleFactor
  }
)
```

## Component Styling

### Document Card
- Height: `95 * scaleFactor`
- Background: White with shadow
- Border radius: `16.689 * scaleFactor`
- Padding: `14.305 * scaleFactor`

### Info Box
- Background: `Colors.blue.shade50`
- Border radius: `16.689 * scaleFactor`
- Icon: Info outline in blue
- Text: Gray (#4A5565)

### Submit Button
- Height: `57.22 * scaleFactor`
- Background: Blue (#00AAF3)
- Text: Bold white, size `19.073 * scaleFactor`
- Loading state: CircularProgressIndicator

## Database Schema (TODO)

### verification_requests table
```sql
CREATE TABLE verification_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  gov_id_url TEXT NOT NULL,
  selfie_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- pending, approved, rejected
  submitted_at TIMESTAMP DEFAULT NOW(),
  reviewed_at TIMESTAMP,
  reviewed_by UUID REFERENCES auth.users(id),
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Update users table
```sql
ALTER TABLE users
ADD COLUMN is_verified TEXT DEFAULT 'unverified'; -- unverified, pending, verified
```

## Supabase Storage Buckets

### Create Buckets
```sql
-- Government IDs bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('government-ids', 'government-ids', false);

-- Selfies bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('selfies', 'selfies', false);
```

### Storage Policies
```sql
-- Allow authenticated users to upload their own documents
CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'government-ids' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Similar policy for selfies bucket
```

## Upload Implementation (TODO)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _uploadDocuments() async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  // Upload Government ID
  final govIdPath = 'government-ids/$userId/${widget.governmentIdFileName}';
  await supabase.storage
      .from('government-ids')
      .upload(govIdPath, widget.governmentIdFile!);

  final govIdUrl = supabase.storage
      .from('government-ids')
      .getPublicUrl(govIdPath);

  // Upload Selfie
  final selfiePath = 'selfies/$userId/${widget.selfieFileName}';
  await supabase.storage
      .from('selfies')
      .upload(selfiePath, widget.selfieFile!);

  final selfieUrl = supabase.storage
      .from('selfies')
      .getPublicUrl(selfiePath);

  // Create verification request
  await supabase.from('verification_requests').insert({
    'user_id': userId,
    'gov_id_url': govIdUrl,
    'selfie_url': selfieUrl,
    'status': 'pending',
  });

  // Update user status
  await supabase.from('users').update({
    'is_verified': 'pending',
  }).eq('id', userId);
}
```

## Testing

### Current Testing Mode
- Navigation works without actual file uploads
- Mock submission with 2-second delay
- Success message displayed
- Returns to root route

### Test Flow
1. Navigate through all 3 steps
2. Click "Submit For Verification"
3. See loading indicator
4. See success message
5. Return to landing page

## Next Steps

### Immediate
1. ✅ Create ReviewDocumentsScreen widget
2. ✅ Implement UI with all components
3. ✅ Add navigation from Step 2
4. ✅ Pass file data between screens
5. ✅ Create documentation

### Backend Integration (TODO)
1. Create Supabase Storage buckets
2. Set up storage policies
3. Implement file upload logic
4. Create verification_requests table
5. Update users table with is_verified column
6. Implement document viewer
7. Create "Under Review" status screen
8. Add admin review interface
9. Implement email notifications
10. Add error handling for upload failures

## Dependencies

### Current
- `flutter/material.dart` - UI framework
- `dart:io` - File handling
- Custom utilities: `helpers.dart` (ResponsiveHelper)

### Needed for Production
- `supabase_flutter` - Already installed
- `photo_view` or `flutter_image_preview` - For document viewing

## Notes

- All validation is currently commented out for testing
- File parameters may be null in testing mode
- Production implementation needs proper error handling
- Consider adding retry logic for failed uploads
- Add upload progress indicators for large files
- Implement offline detection before submission
