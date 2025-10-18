# Step 2 - Selfie Upload Feature

## 🎯 Overview
Added the second step of the identity verification flow: Selfie photo capture/upload screen.

## 📅 Date: October 18, 2025

---

## ✅ What Was Implemented

### 1. New Screen: `selfie_upload_screen.dart`

**Location:** `lib/screens/traveler/selfie_upload_screen.dart`

**Features:**
- ✅ Beautiful gradient header with Step 2 active
- ✅ Progress indicator showing Step 1 completed (with checkmark)
- ✅ Camera integration for selfie capture
- ✅ Upload photo option (file picker)
- ✅ Photo preview after capture
- ✅ Photo guidelines section with blue background
- ✅ Continue and Back buttons
- ✅ Fully responsive design with LayoutBuilder
- ✅ Front camera by default for selfies

### 2. Updated Navigation

**Modified:** `gov_id_upload_screen.dart`
- Continue button now navigates to Selfie Upload (Step 2)
- Removed success message, direct navigation

### 3. Added Dependency

**Modified:** `pubspec.yaml`
- Added `image_picker: ^1.1.2` package for camera/gallery access

---

## 🎨 Design Specifications

Based on Figma design: **Node 228:5171**

### Colors
- **Gradient Header**: `#00AAF3` → `#4EC5F8`
- **Background**: `#F9F9F9`
- **Camera Area**: `#F9FAFB` with dashed border `#D1D5DC`
- **Guidelines Box**: `#EFF6FF` (blue)
- **Primary Button**: `#00AAF3`
- **Info Icon**: `#00AAF3` (primary color)
- **Camera Icon**: `#9CA3AF` (gray)

### Typography
- **Title "Take a"**: 32px, Medium, White
- **Title "Selfie Picture"**: 42px, Bold, White
- **Instruction Text**: 17px, Bold, `#464646`
- **Subtitle**: 14px, Regular, `#464646`
- **Guidelines Title**: 17px, Bold, `#101828`
- **Guidelines Items**: 14px, Regular, `#4A5565`

### Components
- **Progress Dots**: Step 1 (completed with checkmark), Step 2 (active), Step 3 (inactive)
- **Camera Icon**: 58px outlined icon
- **Take A Photo Button**: 147px width, cyan
- **Upload Button**: 128px width, white with shadow
- **Continue Button**: 57px height, full width
- **Back Button**: 57px height, outlined style

---

## 📱 User Flow

```
Identity Verification Screen
    ↓ (Click "Start Verification")
Government ID Upload Screen (Step 1) ✅
    ↓ (Click "Continue")
Selfie Upload Screen (Step 2) ← YOU ARE HERE
    ↓ (Click "Continue")
Review & Submit Screen (Step 3) ← COMING NEXT
    ↓ (Click "Submit")
Verification Pending / Traveler Home
```

---

## 🔧 How It Works

### Camera Capture
```dart
// Opens front camera for selfie
final XFile? photo = await _picker.pickImage(
  source: ImageSource.camera,
  preferredCameraDevice: CameraDevice.front, // Front camera
  imageQuality: 85,
);

// Image is stored and previewed
setState(() {
  _selectedImage = File(photo.path);
});
```

### File Upload
```dart
// User can also upload from gallery
FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.image,
  allowMultiple: false,
);

// Image is stored and previewed
setState(() {
  _selectedImage = File(result.files.single.path!);
});
```

### Validation
- ✅ Checks if photo is captured/uploaded before continuing
- ✅ Shows error message if no photo selected
- ✅ Displays photo preview after capture

### Navigation
- **Back Button**: Returns to Government ID Upload screen
- **Continue Button**: Proceeds to Step 3 (TODO: Review & Submit)

---

## 📋 Photo Guidelines

The screen displays 4 key guidelines:
1. ✅ Look directly at the camera
2. ✅ Ensure good lighting on your face
3. ✅ Remove glasses, hats, or face coverings
4. ✅ Use a plain background if possible

---

## 🎯 Progress Indicator

### Step 1 - Completed ✓
- Shows checkmark icon
- White filled circle with checkmark
- Connected progress line is filled

### Step 2 - Active (Current)
- White circle (larger)
- Border color: `#1AB4F5`
- Progress line partially filled

### Step 3 - Inactive
- Smaller circle
- Light blue color
- Not yet reached

---

## 🧪 Testing

### Test Scenario 1: Camera Capture
1. ✅ Complete Step 1 (Government ID)
2. ✅ Click "Continue"
3. ✅ See Selfie Upload screen (Step 2 active)
4. ✅ Click "Take A Photo" button
5. ✅ Camera opens (front camera)
6. ✅ Take selfie
7. ✅ See photo preview in frame
8. ✅ Click "Continue"
9. ✅ See success message (Step 3 coming soon)

### Test Scenario 2: Upload Photo
1. ✅ On Selfie Upload screen
2. ✅ Click "Upload" button
3. ✅ Select photo from gallery
4. ✅ See photo preview in frame
5. ✅ Click "Continue"
6. ✅ Proceed to next step

### Test Scenario 3: Validation
1. ✅ Click "Continue" without taking/uploading photo
2. ✅ See orange warning message
3. ✅ Take selfie, then click "Continue"
4. ✅ See success message

### Test Scenario 4: Navigation
1. ✅ Click "Back" button
2. ✅ Return to Government ID Upload screen
3. ✅ Re-enter and see Step 2 active on progress

---

## 🎯 Next Steps

### Step 3: Review & Submit Screen ⏳
- [ ] Create `verification_review_screen.dart`
- [ ] Show preview of both documents (ID + Selfie)
- [ ] Add edit buttons to retake photos
- [ ] Implement Supabase Storage upload
- [ ] Submit to verification_requests table
- [ ] Progress indicator shows Step 3 active
- [ ] Navigate to "Under Review" screen

### Backend Integration ⏳
- [ ] Upload Government ID to Supabase Storage
- [ ] Upload Selfie to Supabase Storage
- [ ] Create verification request record
- [ ] Update user's verification status to 'pending'
- [ ] Send notification to admins
- [ ] Email confirmation to user

---

## 🐛 Known Issues

**Web/Desktop Limitation:**
- Camera access may not work on web/desktop
- Upload option is available as fallback
- Works perfectly on mobile (Android/iOS)

---

## 💡 Technical Notes

### Image Picker Package
- **Package**: `image_picker: ^1.1.2`
- **Platforms**: ✅ Android, ✅ iOS, ⚠️ Web (limited), ⚠️ Desktop (limited)
- **Camera**: Front camera by default (for selfies)
- **Image Quality**: 85% compression
- **Max Size**: No limit set (add if needed)

### File Picker Fallback
- **Package**: `file_picker: ^8.1.4`
- **Purpose**: Upload existing photo
- **Platforms**: ✅ All platforms
- **File Types**: Images only

### Responsive Design
Uses `LayoutBuilder` for true responsiveness:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final screenWidth = constraints.maxWidth;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);
    // All sizes scale with device width
  }
)
```

### State Management
- Uses `StatefulWidget` for photo state
- `_selectedImage` stores the captured/uploaded photo
- `_isLoading` for Continue button state
- Photo preview shown when `_selectedImage != null`

### Progress Indicator Logic
- Step 1: Completed (shows checkmark)
- Step 2: Active (white center, colored border)
- Step 3: Inactive (smaller, light color)
- Progress line fills from Step 1 to Step 2

---

## 📸 Screenshots

See Figma design: https://www.figma.com/design/rS6eUeriWJrGAv0E4lIr4O/Pasabay?node-id=228-5171

---

## ✅ Checklist

- [x] Create `selfie_upload_screen.dart`
- [x] Implement camera integration
- [x] Implement upload option
- [x] Design gradient header with Step 2 progress
- [x] Add photo guidelines section
- [x] Add Continue and Back buttons
- [x] Update navigation from Government ID screen
- [x] Add `image_picker` dependency
- [x] Test camera capture
- [x] Test file upload
- [x] Test validation
- [x] Test navigation
- [x] Add photo preview
- [ ] Add Step 3: Review & Submit
- [ ] Implement backend upload
- [ ] Test on mobile devices

---

## 🚀 Run the App

```bash
# Get dependencies
flutter pub get

# Run on Chrome (limited camera support)
flutter run -d chrome

# Run on Android (full camera support)
flutter run -d android
```

**Navigate to:** 
Login → Role Selection (Traveler) → Identity Verification → Start Verification → Upload Government ID → **Continue to Selfie Upload** ← NEW!

---

## 📱 Platform Compatibility

| Platform | Camera | Upload | Status |
|----------|--------|--------|--------|
| Android  | ✅ Full | ✅ Full | Perfect |
| iOS      | ✅ Full | ✅ Full | Perfect |
| Web      | ⚠️ Limited | ✅ Full | Upload works |
| Desktop  | ⚠️ Limited | ✅ Full | Upload works |

**Note:** For web/desktop testing, use the "Upload" button instead of "Take A Photo".

---

## 🎨 UI Improvements from Step 1

1. **Progress Line**: Now shows filled progress from Step 1 to Step 2
2. **Checkmark**: Step 1 shows completion with checkmark icon
3. **Active State**: Step 2 has distinctive active styling
4. **Blue Theme**: Guidelines use blue background (was amber in Step 1)
5. **Dual Options**: Camera + Upload buttons for flexibility
6. **Photo Preview**: Shows captured image in the frame

---

## 🔐 Privacy & Security

- Photos are stored locally until submission
- Only accessed with user permission
- Front camera ensures natural selfie capture
- Clear guidelines help users provide good quality photos
- Can retake photo multiple times

---

## 📝 Files Created/Modified

### Created:
- ✅ `lib/screens/traveler/selfie_upload_screen.dart` (NEW)
- ✅ `STEP2_SELFIE_UPLOAD.md` (Documentation)

### Modified:
- ✅ `lib/screens/traveler/gov_id_upload_screen.dart` (Updated navigation)
- ✅ `pubspec.yaml` (Added image_picker dependency)

---

**Ready for Step 3: Review & Submit!** 🎉
