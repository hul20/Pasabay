# 🔑 API Keys Setup - Quick Start

**Important:** This project uses protected API keys that are NOT committed to Git.

---

## 🚀 Quick Setup (2 Minutes)

### **Step 1: Copy the template**
```bash
cd android
cp local.properties.example local.properties
```

### **Step 2: Add your Google Maps API key**
Edit `android/local.properties`:
```properties
GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
```

### **Step 3: Run the app**
```bash
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 🗺️ Getting a Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Maps SDK for Android**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy the key (starts with `AIzaSy...`)
6. Paste it in `android/local.properties`

**Full guide:** See `SECURITY_SETUP.md`

---

## ⚠️ Important

- ✅ `android/local.properties` is ignored by Git
- ❌ **NEVER** commit files containing actual API keys
- ✅ Use `local.properties.example` for templates only

---

## 🆘 Troubleshooting

**Map not showing?**
1. Check `android/local.properties` exists
2. Verify API key is correct
3. Run `flutter clean && flutter pub get`
4. Rebuild the app

**More help:** See `SECURITY_SETUP.md`

---

## 📚 Documentation

- `SECURITY_SETUP.md` - Complete security guide
- `GET_GOOGLE_MAPS_API_KEY.md` - Step-by-step API key setup
- `local.properties.example` - Template file

