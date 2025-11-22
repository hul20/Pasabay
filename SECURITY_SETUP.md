# 🔐 Security Setup Guide - API Key Protection

This guide explains how your API keys are now secured and protected from being committed to Git.

---

## ✅ What Was Done

Your Google Maps API key has been secured using the following best practices:

### 1. **API Key Moved to `local.properties`**
- ✅ API key is now in `android/local.properties`
- ✅ This file is **NOT tracked by Git** (added to `.gitignore`)
- ✅ Safe to keep on your local machine

### 2. **Template File Created**
- ✅ Created `android/local.properties.example`
- ✅ This is a template for other developers
- ✅ Contains placeholder values (safe to commit)

### 3. **`.gitignore` Updated**
- ✅ Added protection for API key files:
  - `android/local.properties`
  - `ios/Flutter/local.properties`
  - `.env` files
  - `lib/config/api_keys.dart`

### 4. **Android Build System Updated**
- ✅ Modified `android/app/build.gradle.kts` to read from `local.properties`
- ✅ Updated `AndroidManifest.xml` to use placeholder
- ✅ API key is injected at build time (never in source code)

---

## 📁 File Structure

```
Pasabay-1/
├── android/
│   ├── local.properties           ← 🔒 Your actual API key (IGNORED by Git)
│   ├── local.properties.example   ← ✅ Template (SAFE to commit)
│   └── app/
│       ├── build.gradle.kts       ← ✅ Reads from local.properties
│       └── src/main/
│           └── AndroidManifest.xml ← ✅ Uses placeholder
└── .gitignore                      ← ✅ Protects sensitive files
```

---

## 🚀 How It Works

### **Build Time Flow:**

```
┌──────────────────────────────────────┐
│ 1. Gradle reads local.properties     │
│    GOOGLE_MAPS_API_KEY=AIza...       │
└──────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────┐
│ 2. build.gradle.kts extracts key     │
│    val googleMapsApiKey = ...        │
└──────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────┐
│ 3. Injects into AndroidManifest.xml │
│    ${GOOGLE_MAPS_API_KEY}            │
└──────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────┐
│ 4. App builds with actual API key    │
│    (Key never in source code!)       │
└──────────────────────────────────────┘
```

---

## 👥 For Team Members / New Developers

If someone clones your repository, they need to set up their own API key:

### **Setup Steps:**

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd Pasabay-1
   ```

2. **Copy the example file**
   ```bash
   cd android
   cp local.properties.example local.properties
   ```

3. **Edit `local.properties`**
   ```properties
   # Open the file and replace YOUR_GOOGLE_MAPS_API_KEY_HERE with actual key
   GOOGLE_MAPS_API_KEY=AIzaSyC1234567890abcdefghijklmnopqrstuvw
   ```

4. **Run the app**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 🔍 Verify Security

### **Check what Git sees:**

```bash
# This should NOT show local.properties
git status

# This should show it's ignored
git check-ignore android/local.properties
# Output: android/local.properties
```

### **Check `.gitignore` is working:**

```bash
# Try adding it (should be ignored)
git add android/local.properties
# Output: The following paths are ignored by one of your .gitignore files...
```

---

## ⚠️ Important Security Notes

### **✅ SAFE to commit:**
- ✅ `android/local.properties.example` (template)
- ✅ `android/app/build.gradle.kts` (build script)
- ✅ `android/app/src/main/AndroidManifest.xml` (placeholder)
- ✅ `.gitignore` (protection rules)

### **❌ NEVER commit:**
- ❌ `android/local.properties` (contains actual key)
- ❌ Any file with `AIzaSy...` API key visible
- ❌ Files listed in `.gitignore`

---

## 🔧 Troubleshooting

### **Problem: "API key not found" error**

**Solution:**
1. Check if `android/local.properties` exists
2. Verify it contains: `GOOGLE_MAPS_API_KEY=AIza...`
3. Run `flutter clean && flutter pub get`
4. Rebuild the app

### **Problem: Map still not showing**

**Solution:**
1. Verify the API key is correct in `local.properties`
2. Check the key has proper permissions in Google Cloud Console
3. Clean and rebuild:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter run
   ```

### **Problem: Git is trying to commit my API key**

**Solution:**
1. Remove it from tracking:
   ```bash
   git rm --cached android/local.properties
   git commit -m "Remove API key from tracking"
   ```
2. Verify `.gitignore` contains `android/local.properties`
3. Never use `git add -A` or `git add .` without checking first

---

## 📊 Current Protection Status

| File | Status | Protected? |
|------|--------|------------|
| `android/local.properties` | Contains API key | ✅ YES (in .gitignore) |
| `android/local.properties.example` | Template only | ✅ Safe to commit |
| `AndroidManifest.xml` | Uses placeholder | ✅ Safe to commit |
| `build.gradle.kts` | Reads from file | ✅ Safe to commit |
| `.gitignore` | Protection rules | ✅ Safe to commit |

---

## 🔐 Additional Security Recommendations

### **1. API Key Restrictions (Google Cloud Console)**

Add these restrictions to your Google Maps API key:

**Application restrictions:**
- Android apps
- Package name: `com.pasabay.app`
- SHA-1 fingerprint: `[your-app-fingerprint]`

**API restrictions:**
- Maps SDK for Android
- Geocoding API
- Places API (if used)

### **2. Environment Variables (Advanced)**

For even more security, use environment variables:

```bash
# In your shell profile (.bashrc, .zshrc)
export GOOGLE_MAPS_API_KEY="AIzaSy..."

# In build.gradle.kts
val googleMapsApiKey = System.getenv("GOOGLE_MAPS_API_KEY") 
    ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY") 
    ?: "YOUR_API_KEY_HERE"
```

### **3. CI/CD Pipeline**

If using GitHub Actions, GitLab CI, etc.:

```yaml
# .github/workflows/build.yml
- name: Create local.properties
  run: |
    echo "GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}" > android/local.properties
```

Then add the key as a **secret** in your repository settings.

---

## ✅ Security Checklist

Before committing to Git:

- [ ] Verified `android/local.properties` is in `.gitignore`
- [ ] Checked `git status` doesn't show API key files
- [ ] Confirmed `AndroidManifest.xml` uses `${GOOGLE_MAPS_API_KEY}`
- [ ] Ensured no hardcoded keys in any `.dart` files
- [ ] Tested app builds successfully with new setup
- [ ] Created `local.properties.example` for team members
- [ ] Documented setup process for new developers

---

## 📚 Additional Resources

- [Google Maps API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Flutter Security Guidelines](https://docs.flutter.dev/security)
- [Git Security Best Practices](https://docs.github.com/en/code-security/getting-started/best-practices-for-preventing-data-leaks-in-your-organization)

---

## 🎉 Summary

✅ **Your API key is now secure!**

- Removed from source code
- Protected by `.gitignore`
- Loaded at build time only
- Template provided for team members
- Safe to push to GitHub/GitLab

**You can now safely commit and push your code without exposing your API keys!** 🔒✨

