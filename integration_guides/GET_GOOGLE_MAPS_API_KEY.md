# 🗺️ How to Get Google Maps API Key (Step-by-Step)

## ⚡ Quick Fix: App Works Without Maps!

**Good News:** I've updated the code so the app works **WITHOUT** Google Maps API! 

Just run:
```bash
flutter clean
flutter pub get
flutter run
```

✅ **The app will launch successfully!** Maps will show a placeholder, but trip logging works perfectly.

---

## 🎯 Getting Google Maps API Key (10 minutes)

If you want the full map experience later, follow these steps:

### **Step 1: Create Google Cloud Account** (2 min)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Accept terms if prompted

**Note:** Google requires a credit card, but gives $300 free credits. You won't be charged for normal usage.

---

### **Step 2: Create a Project** (1 min)

1. Click the **project dropdown** at the top
2. Click **"New Project"**
3. Enter project name: `Pasabay` or `PasabayMaps`
4. Click **"Create"**
5. Wait for project creation (~30 seconds)
6. Select your new project

---

### **Step 3: Enable Billing** (2 min)

⚠️ **Required:** Google Maps requires billing enabled (but it's free for moderate use)

1. Go to **Billing** in the menu
2. Click **"Link a billing account"** or **"Add Billing Account"**
3. Enter payment details
4. You get **$300 free credits** (won't be charged for normal dev use)

**Cost for your app:**
- First 28,000 map loads per month: **FREE**
- First 40,000 geocoding requests: **FREE**
- Your usage will likely be well within free tier

---

### **Step 4: Enable Required APIs** (3 min)

1. Go to **APIs & Services** → **Library**
2. Search and enable these APIs (click each, then click "Enable"):

   ✅ **Maps SDK for Android**
   - Search: "Maps SDK for Android"
   - Click the result
   - Click "Enable"

   ✅ **Maps SDK for iOS** 
   - Search: "Maps SDK for iOS"
   - Click the result
   - Click "Enable"

   ✅ **Geocoding API**
   - Search: "Geocoding API"
   - Click the result
   - Click "Enable"

   ✅ **Places API** (Optional, for autocomplete)
   - Search: "Places API"
   - Click the result
   - Click "Enable"

---

### **Step 5: Create API Key** (2 min)

1. Go to **APIs & Services** → **Credentials**
2. Click **"+ CREATE CREDENTIALS"**
3. Select **"API Key"**
4. Copy the API key that appears
5. **IMPORTANT:** Copy it now! You'll need it next.

**Your API key will look like:**
```
AIzaSyC1234567890abcdefghijklmnopqrstuvw
```

---

### **Step 6: Restrict the API Key (Recommended)** (2 min)

For security, restrict your API key:

1. Click **"Edit API key"** (or the pencil icon)
2. Under **"Application restrictions"**:
   - Select **"Android apps"**
   - Click **"+ Add an item"**
   - Package name: `com.example.pasabay_app` (or your package name)
   - Click **"Done"**

3. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Check these APIs:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Geocoding API
     - Places API
   - Click **"Save"**

---

## 📱 Step 7: Add API Key to Your App

### **For Android:**

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  
  <!-- Add permissions BEFORE <application> -->
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

  <application
      android:label="pasabay_app"
      android:name="${applicationName}"
      android:icon="@mipmap/ic_launcher">
      
      <!-- ADD THIS META-DATA TAG -->
      <meta-data
          android:name="com.google.android.geo.API_KEY"
          android:value="YOUR_API_KEY_HERE"/>
      
      <!-- Rest of your application config... -->
      <activity
          android:name=".MainActivity"
          ...>
      </activity>
  </application>
</manifest>
```

**Replace `YOUR_API_KEY_HERE` with your actual API key!**

---

### **For iOS:**

1. **Edit `ios/Runner/AppDelegate.swift`:**

```swift
import UIKit
import Flutter
import GoogleMaps  // ADD THIS LINE

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ADD THIS LINE with your API key
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

2. **Edit `ios/Runner/Info.plist`:**

Add these inside the `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your travel route.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track your trips.</string>
```

3. **Edit `ios/Podfile`:**

Make sure it has:

```ruby
platform :ios, '12.0'

# Uncomment this line
use_frameworks!
```

4. **Install pods:**

```bash
cd ios
pod install
cd ..
```

---

## 🚀 Step 8: Enable Google Maps in Code

After adding your API key, enable Google Maps in the code:

Edit `lib/screens/traveler_home_page.dart` and find `_buildMapWidget` method:

**Change this line:**
```dart
// TODO: Enable Google Maps after API key is configured
return Container(
```

**To:**
```dart
// Google Maps is now configured!
return GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(14.5995, 120.9842),
    zoom: 11,
  ),
  markers: _markers,
  polylines: _polylines,
  onMapCreated: (GoogleMapController controller) {
    _mapController = controller;
  },
  myLocationEnabled: false,
  myLocationButtonEnabled: false,
  zoomControlsEnabled: false,
  mapType: MapType.normal,
);
```

---

## 🏃 Step 9: Run Your App

```bash
flutter clean
flutter pub get
flutter run
```

✅ **You should now see the real Google Map!**

---

## 🧪 Test It

1. **Launch app**
2. **Login as traveler**
3. **Go to home page**
4. **Enter locations**:
   - Departure: "Manila, Philippines"
   - Destination: "Baguio, Philippines"
5. **Watch the map**:
   - Green marker for departure
   - Red marker for destination
   - Auto-zoom to show both

---

## 🐛 Troubleshooting

### **Issue: Map shows blank/gray**

**Causes:**
- API key not added correctly
- Billing not enabled
- APIs not enabled
- Wrong package name in restrictions

**Fix:**
1. Double-check API key is exactly copied
2. Verify billing is enabled
3. Check all 4 APIs are enabled
4. Try unrestricted key first (for testing)

---

### **Issue: "Authorization failure"**

**Fix:**
1. Go to Google Cloud Console
2. APIs & Services → Credentials
3. Edit your API key
4. Set to "None" for Application restrictions (testing only)
5. Save and wait 5 minutes
6. Try again

---

### **Issue: Still crashing**

**Fix:**
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

---

## 💰 Cost Estimate

### **Free Tier (Monthly):**
- 28,000 map loads: **FREE**
- 40,000 geocoding requests: **FREE**  
- 100,000 routes requests: **FREE**

### **Your Expected Usage:**
- Development: ~500 map loads
- Testing: ~100 geocoding requests
- **Total cost: $0 (well within free tier)**

### **Production (100 users):**
- ~10,000 map loads/month
- ~5,000 geocoding requests/month
- **Total cost: Still $0 (within free tier)**

**You won't be charged unless you have thousands of users!**

---

## 📋 Quick Checklist

Before running:
- [ ] Google Cloud project created
- [ ] Billing enabled
- [ ] Maps SDK for Android enabled
- [ ] Maps SDK for iOS enabled
- [ ] Geocoding API enabled
- [ ] API key created and copied
- [ ] API key added to AndroidManifest.xml
- [ ] API key added to AppDelegate.swift
- [ ] Permissions added to Info.plist
- [ ] Pods installed (iOS)
- [ ] Code updated to use GoogleMap widget
- [ ] `flutter clean` executed
- [ ] `flutter pub get` executed

---

## 🎉 Summary

### **Option 1: No Google Maps (Works Now)**
```bash
flutter run
```
✅ App works with placeholder map

### **Option 2: With Google Maps (10 min setup)**
1. Get API key from Google Cloud Console
2. Add to AndroidManifest.xml and AppDelegate.swift
3. Enable GoogleMap widget in code
4. Run app

✅ Full map experience!

---

## 📚 More Resources

- [Google Maps Platform](https://developers.google.com/maps)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)

---

**Need help? The app works great without Maps for now. Add it later when ready!** 🚀

