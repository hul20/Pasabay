# Step 1 - Government ID Upload Feature

## 🎯 Overview
Added the first step of the identity verification flow: Government ID document upload screen.

## 📅 Date: October 18, 2025

---

## ✅ What Was Implemented

### 1. New Screen: `gov_id_upload_screen.dart`

**Location:** `lib/screens/traveler/gov_id_upload_screen.dart`

**Features:**
- ✅ Beautiful gradient header matching Figma design
- ✅ 3-step progress indicator (Step 1 active)
- ✅ File picker integration for document upload
- ✅ Drag-and-drop style upload area
- ✅ Document requirements section with amber background
- ✅ Continue and Back buttons
- ✅ Fully responsive design with LayoutBuilder
- ✅ File validation (jpg, jpeg, png, pdf)

### 2. Updated Navigation

**Modified:** `identity_verification_screen.dart`
- "Start Verification" button now navigates to Government ID upload
- Removed "coming soon" message

### 3. Added Dependency

**Modified:** `pubspec.yaml`
- Added `file_picker: ^8.1.4` package for file selection

---

## 🎨 Design Specifications

Based on Figma design: **Node 228:5032**

### Colors
- **Gradient Header**: `#00AAF3` → `#4EC5F8`
- **Background**: `#F9F9F9`
- **Upload Area**: `#F9FAFB` with dashed border `#D1D5DC`
- **Requirements Box**: `#FFF9E6` (amber)
- **Primary Button**: `#00AAF3`
- **Warning Icon**: `#E17100`

### Typography
- **Title "Upload Your"**: 32px, Medium, White
- **Title "Government ID"**: 42px, Bold, White
- **Upload Text**: 17px, Bold, `#101828`
- **Description**: 14px, Regular, `#4A5565`
- **Requirements Title**: 17px, Bold, `#101828`
- **Requirements Items**: 14px, Regular, `#4A5565`

### Components
- **Progress Dots**: 3 circular indicators (38px, 29px, 29px)
- **Upload Icon**: 58px rounded container
- **Choose File Button**: Cyan with upload icon
- **Continue Button**: 57px height, full width
- **Back Button**: 57px height, outlined style

---

## 📱 User Flow

```
Identity Verification Screen
    ↓ (Click "Start Verification")
Government ID Upload Screen (Step 1) ← YOU ARE HERE
    ↓ (Click "Continue")
Selfie Upload Screen (Step 2) ← COMING NEXT
    ↓ (Click "Continue")
Review & Submit Screen (Step 3) ← COMING NEXT
    ↓ (Click "Submit")
Verification Pending / Traveler Home
```

---

## 🔧 How It Works

### File Selection
```dart
// User taps upload area or "Choose File" button
FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
);

// File is selected and stored
setState(() {
  _selectedFile = File(result.files.single.path!);
  _fileName = result.files.single.name;
});
```

### Validation
- ✅ Checks if file is selected before continuing
- ✅ Only allows image files (jpg, jpeg, png) and PDF
- ✅ Shows error message if no file selected

### Navigation
- **Back Button**: Returns to Identity Verification screen
- **Continue Button**: Proceeds to Step 2 (TODO: Selfie upload)

---

## 📋 Document Requirements

The screen displays 4 key requirements:
1. ✅ Document should be valid and not expired
2. ✅ All corners of the ID must be visible
3. ✅ Text should be clear and readable
4. ✅ No glare or shadows on the document

---

## 🧪 Testing

### Test Scenario 1: Upload Flow
1. ✅ Log in as Traveler
2. ✅ Navigate to Identity Verification screen
3. ✅ Click "Start Verification"
4. ✅ See Government ID Upload screen with gradient header
5. ✅ Click "Choose File" button
6. ✅ Select an image or PDF
7. ✅ See filename displayed in upload area
8. ✅ Click "Continue"
9. ✅ See success message (Step 2 coming soon)

### Test Scenario 2: Validation
1. ✅ Click "Continue" without selecting file
2. ✅ See orange warning message
3. ✅ Select file, then click "Continue"
4. ✅ See success message

### Test Scenario 3: Navigation
1. ✅ Click "Back" button
2. ✅ Return to Identity Verification screen
3. ✅ Re-enter and see progress indicator on Step 1

---

## 🎯 Next Steps

### Step 2: Selfie Upload Screen
- [ ] Create `selfie_upload_screen.dart`
- [ ] Implement camera integration
- [ ] Add selfie capture UI
- [ ] Progress indicator shows Step 2 active

### Step 3: Review & Submit Screen
- [ ] Create `verification_review_screen.dart`
- [ ] Show preview of uploaded documents
- [ ] Implement Supabase Storage upload
- [ ] Submit to verification_requests table
- [ ] Progress indicator shows Step 3 active

### Backend Integration
- [ ] Upload files to Supabase Storage
- [ ] Create verification request record
- [ ] Update user's verification status
- [ ] Send notification to admins

---

## 🐛 Known Issues

None currently. File picker works on all platforms.

---

## 💡 Technical Notes

### File Picker Package
- **Package**: `file_picker: ^8.1.4`
- **Platforms**: ✅ Android, ✅ iOS, ✅ Web, ✅ Desktop
- **File Types**: Images (jpg, jpeg, png) and PDF
- **Max Size**: No limit set (add if needed)

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
- Uses `StatefulWidget` for file selection state
- `_selectedFile` stores the selected file
- `_fileName` displays in UI
- `_isLoading` for Continue button state

---

## 📸 Screenshots

See Figma design: https://www.figma.com/design/rS6eUeriWJrGAv0E4lIr4O/Pasabay?node-id=228-5032

---

## ✅ Checklist

- [x] Create `gov_id_upload_screen.dart`
- [x] Implement file picker
- [x] Design gradient header with progress
- [x] Add document requirements section
- [x] Add Continue and Back buttons
- [x] Update navigation from identity verification screen
- [x] Add `file_picker` dependency
- [x] Test file selection
- [x] Test validation
- [x] Test navigation
- [ ] Add Step 2: Selfie Upload
- [ ] Add Step 3: Review & Submit
- [ ] Implement backend upload

---

## 🚀 Run the App

```bash
# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Android
flutter run -d android
```

Navigate to: **Login → Role Selection (Traveler) → Identity Verification → Start Verification**
