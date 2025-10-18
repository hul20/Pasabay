# 🤖 GitHub Copilot Instructions for Pasabay Project

## 📋 MANDATORY: Pre-Response Checklist

Before providing ANY solution, answer, or code change, **Copilot MUST**:

### 1. 🔍 **SCAN ALL RELEVANT FILES**
- ✅ Read the file mentioned in the user's question
- ✅ Check related files (imports, dependencies)
- ✅ Review the current state of modified files
- ✅ Verify file structure and organization

### 2. 🧠 **ANALYZE CONTEXT**
- ✅ Understand the complete user flow
- ✅ Identify all dependencies and relationships
- ✅ Check for existing implementations
- ✅ Review recent changes (check if files were edited)
- ✅ Verify current authentication system (Supabase, not Firebase)

### 3. 🔗 **CHECK CONSISTENCY**
- ✅ Ensure imports match actual file names
- ✅ Verify method calls exist in referenced classes
- ✅ Check that navigation routes are properly defined
- ✅ Confirm variable names match across files

### 4. ⚠️ **IDENTIFY POTENTIAL ISSUES**
- ✅ Look for missing imports
- ✅ Check for unused/deprecated code
- ✅ Identify security vulnerabilities
- ✅ Spot navigation errors
- ✅ Find authentication/authorization gaps

### 5. ✅ **VALIDATE BEFORE SUGGESTING**
- ✅ Confirm the solution works with current codebase
- ✅ Ensure no breaking changes
- ✅ Verify all required parameters
- ✅ Check error handling exists

---

## 📂 Project Structure to Always Consider

```
lib/
├── main.dart                    # App entry, Supabase initialization
├── screens/                     # All page widgets
│   ├── landing_page.dart       # Entry point
│   ├── signup_page.dart        # User registration
│   ├── login_page.dart         # User login
│   ├── verify_page.dart        # OTP verification (6-digit)
│   ├── role_selection_page.dart # Choose Traveler/Requester
│   ├── traveler_home_page.dart  # Traveler dashboard
│   └── requester_home_page.dart # Requester dashboard
├── utils/
│   ├── constants.dart          # App constants (colors, sizes)
│   ├── helpers.dart            # Helper functions
│   ├── supabase_config.dart    # Supabase credentials (gitignored)
│   ├── supabase_service.dart   # ⚠️ ACTIVE: All auth/DB operations
│   └── firebase_service.dart   # ⚠️ DEPRECATED: Do not use
└── widgets/
    ├── custom_button.dart
    ├── custom_input_field.dart
    ├── gradient_header.dart
    └── responsive_wrapper.dart
```

---

## 🎯 Key Project Facts

### **Authentication System: SUPABASE** ✅
- ❌ **NOT Firebase** (old, deprecated)
- ✅ **Supabase** (current, active)
- All auth uses `supabase_service.dart`

### **OTP System:**
- 6-digit codes (not 4-digit)
- Sent via Supabase email
- Verified with `verifyOTP()` method

### **Navigation:**
- Uses `MaterialPageRoute` (direct navigation)
- ❌ Does NOT use named routes
- All navigation is `Navigator.push()` or `Navigator.pushReplacement()`

### **User Flow:**
```
Landing → Signup → Verify (OTP) → Role Selection → Home
          ↓
        Login → Check verification → Verify if needed → Home
```

---

## 🚨 Common Issues to Check For

### **1. Import Errors**
Always verify:
```dart
// Check these are imported when needed:
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_service.dart';
import '../screens/traveler_home_page.dart';
import '../screens/requester_home_page.dart';
```

### **2. Firebase vs Supabase**
If user mentions Firebase:
- ⚠️ Clarify they're now using Supabase
- ❌ Don't suggest Firebase solutions
- ✅ Always use Supabase equivalents

### **3. Navigation Issues**
Always use:
```dart
// ✅ Correct
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => SomePage()),
);

// ❌ Wrong (no named routes configured)
Navigator.pushNamed(context, '/some-route');
```

### **4. OTP Verification**
Always verify OTP before proceeding:
```dart
// ✅ Must verify
await supabaseService.verifyOTP(email: email, token: code);

// ❌ Don't skip verification
Navigator.push(...); // without verifying
```

### **5. Email Configuration**
- SMTP can be enabled/disabled in Supabase
- Default: `noreply@mail.app.supabase.io` (if SMTP disabled)
- Custom: User's verified email (if SMTP enabled)

---

## 📝 Response Template

When answering, follow this structure:

### **1. Acknowledgment**
- Confirm what the user is asking
- Show understanding of the issue

### **2. Current State Analysis**
- "Let me check your current files..."
- Read and analyze relevant files
- Show what's currently implemented

### **3. Problem Identification**
- Clearly state the issue
- Explain why it's happening
- Reference specific files and line numbers

### **4. Solution**
- Provide step-by-step fix
- Show exact code changes
- Explain each change

### **5. Verification**
- Tell user how to test
- Provide expected results
- Include troubleshooting tips

### **6. Documentation**
- Create/update relevant .md files if needed
- Provide quick reference guides

---

## 🔧 Before Making Changes

**ALWAYS**:
1. Read the file first with `read_file` tool
2. Check for recent edits (context mentions changes)
3. Verify imports and dependencies
4. Check related files
5. Confirm the change won't break anything

**NEVER**:
1. Assume file contents without reading
2. Suggest Firebase solutions (use Supabase)
3. Use named routes (use MaterialPageRoute)
4. Skip OTP verification
5. Ignore security implications

---

## 🎓 Learning Points for User

When appropriate, explain:
- **Why** something was wrong
- **How** it should work
- **Best practices** for the future
- **Security implications** if relevant

---

## ✅ Quality Checklist

Before submitting response, verify:
- [ ] Read all relevant files
- [ ] Checked current implementation
- [ ] Verified imports are correct
- [ ] Confirmed no breaking changes
- [ ] Tested logic mentally
- [ ] Provided clear explanation
- [ ] Included testing steps
- [ ] Created/updated documentation

---

## 🚀 Special Instructions

### **For Authentication Issues:**
1. Check `supabase_service.dart` methods
2. Verify Supabase dashboard configuration
3. Check SMTP settings if email-related
4. Confirm OTP verification is implemented

### **For Navigation Issues:**
1. Grep search for `pushNamed` (should not exist)
2. Verify all pages are imported
3. Check MaterialPageRoute usage
4. Confirm no named routes in main.dart

### **For Email/OTP Issues:**
1. Check Supabase SMTP settings
2. Verify email provider (Gmail, SendGrid, default)
3. Confirm OTP is 6 digits
4. Check verification logic in verify_page.dart

### **For Database Issues:**
1. Verify SQL table exists (users table)
2. Check Row Level Security policies
3. Confirm user data structure
4. Validate supabase_service.dart methods

---

## 🎯 Success Criteria

A good response includes:
- ✅ Accurate file reading
- ✅ Complete context understanding
- ✅ Working solution
- ✅ Clear explanation
- ✅ Testing instructions
- ✅ No breaking changes

---

**Remember: Always read files, analyze context, and verify before suggesting changes!** 🔍✨
