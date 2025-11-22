# 🚗 Trip Logging Feature - Setup Guide

This guide will help you set up the complete trip logging functionality for travelers in the Pasabay app.

## 📋 Table of Contents
1. [Overview](#overview)
2. [Supabase Database Setup](#supabase-database-setup)
3. [Google Maps API Setup](#google-maps-api-setup)
4. [Flutter Configuration](#flutter-configuration)
5. [Testing](#testing)
6. [Features](#features)

---

## 🎯 Overview

The trip logging feature allows travelers to:
- **Log trips** with departure and destination locations
- **Select date and time** for their journey
- **View route preview** on Google Maps
- **Track statistics** (active trips, monthly earnings)
- **Search locations** with autocomplete
- Requesters can later **search and request** services from these logged trips

---

## 🗄️ Supabase Database Setup

### Step 1: Run the SQL Schema

1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file `supabase_trips_schema.sql` from the project root
4. Copy and paste the entire SQL script into the editor
5. Click **Run** to execute

This will create:
- ✅ `trips` table with all necessary columns
- ✅ Row Level Security (RLS) policies
- ✅ Indexes for performance
- ✅ `get_trip_stats()` function for statistics
- ✅ Automatic timestamp triggers

### Step 2: Verify the Schema

Run this query to verify:

```sql
-- Check if table exists
SELECT EXISTS (
  SELECT FROM pg_tables 
  WHERE schemaname = 'public' 
  AND tablename = 'trips'
);

-- Check table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'trips';

-- Check policies
SELECT * FROM pg_policies WHERE tablename = 'trips';
```

### Step 3: Test the Statistics Function

```sql
-- Replace YOUR_USER_ID with actual user ID
SELECT get_trip_stats('YOUR_USER_ID'::uuid);
```

---

## 🗺️ Google Maps API Setup

### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**
   - **Directions API**
   - **Places API**
4. Go to **Credentials** → Create **API Key**
5. Restrict the key (recommended):
   - **Application restrictions**: Set to Android/iOS apps
   - **API restrictions**: Select only the APIs listed above

### Step 2: Configure Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <application ...>
    <!-- Add this inside <application> tag -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
    
    <!-- Rest of your application -->
  </application>
  
  <!-- Add these permissions before <application> tag -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

### Step 3: Configure iOS

1. Edit `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this line with your API key
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

2. Edit `ios/Runner/Info.plist`:

```xml
<dict>
  <!-- Add these permissions -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>This app needs access to location to show your route.</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>This app needs access to location to track your trips.</string>
  
  <!-- Rest of your plist -->
</dict>
```

3. Edit `ios/Podfile`:

```ruby
platform :ios, '12.0'  # Minimum iOS version

# Add this at the top
source 'https://github.com/CocoaPods/Specs.git'
```

### Step 4: Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

---

## 📱 Flutter Configuration

### Step 1: Install Dependencies

All dependencies are already added to `pubspec.yaml`. Just run:

```bash
flutter pub get
```

Dependencies added:
- ✅ `google_maps_flutter: ^2.5.0`
- ✅ `geolocator: ^10.1.0`
- ✅ `geocoding: ^2.1.1`
- ✅ `intl: ^0.19.0`

### Step 2: Update Platform Specific Settings

**Android** - Edit `android/app/build.gradle`:

```gradle
android {
    ...
    defaultConfig {
        ...
        minSdkVersion 21  // Update to minimum 21
        targetSdkVersion 34
        multiDexEnabled true
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

**iOS** - Already configured in Podfile

### Step 3: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Testing

### Test 1: Database Connection

1. Run the app and log in as a traveler
2. Navigate to the home page
3. Check if statistics show (Active Trips: 0, Total Earnings: ₱0)

**Expected**: Statistics load without errors

### Test 2: Location Search

1. Tap on "Departure Location" field
2. Type "Manila, Philippines"
3. Select from autocomplete suggestions

**Expected**: Location coordinates are captured and marker appears on map

### Test 3: Date/Time Selection

1. Tap "Select Date" button
2. Choose a future date
3. Tap "Select Time" button
4. Choose a time

**Expected**: Selected date/time displays on buttons

### Test 4: Trip Registration

**Prerequisites**: 
- Account must be verified (complete identity verification)

**Steps**:
1. Fill in all fields:
   - Departure: "Manila, Philippines"
   - Destination: "Baguio, Philippines"
   - Date: Tomorrow
   - Time: 8:00 AM
2. Verify map shows both markers (green = departure, red = destination)
3. Tap "Register Travel" button

**Expected**:
- ✅ Loading indicator appears
- ✅ Success message: "Trip registered successfully!"
- ✅ Form clears
- ✅ Active Trips count increases by 1
- ✅ Trip appears in database

### Test 5: Verify in Supabase

Go to Supabase Dashboard → Table Editor → `trips`

**Expected**: New row with your trip data

### Test 6: Statistics Update

After registering a trip:

**Expected**:
- Active Trips count increases
- Statistics persist after app restart
- Closing and reopening app shows updated count

---

## ✨ Features

### 1. Trip Logging
- ✅ Departure and destination location input
- ✅ Location autocomplete using Geocoding API
- ✅ Date picker for departure date
- ✅ Time picker for departure time
- ✅ Form validation

### 2. Map Visualization
- ✅ Google Maps integration
- ✅ Green marker for departure
- ✅ Red marker for destination
- ✅ Auto-zoom to show both locations
- ✅ Live preview of route

### 3. Statistics Dashboard
- ✅ Active trips count
- ✅ Monthly earnings display
- ✅ Real-time updates from Supabase
- ✅ Automatic refresh on app resume

### 4. User Experience
- ✅ Beautiful UI matching existing design
- ✅ Responsive scaling
- ✅ Loading indicators
- ✅ Success/error messages
- ✅ Form reset after submission
- ✅ Verification required to log trips

### 5. Backend Integration
- ✅ Supabase database storage
- ✅ Row Level Security (RLS)
- ✅ Efficient queries with indexes
- ✅ Statistics calculation via PostgreSQL function
- ✅ Real-time data sync

---

## 🔐 Security Features

1. **RLS Policies**:
   - Travelers can only view/edit their own trips
   - Requesters can search active trips with available capacity
   - Automatic user ID validation

2. **Input Validation**:
   - All fields required
   - Date must be in future
   - Proper time formatting

3. **Data Constraints**:
   - Trip capacity limits
   - Status validation
   - Automatic timestamp management

---

## 📊 Database Schema

### Trips Table Structure

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| traveler_id | uuid | References auth.users |
| departure_location | text | Starting point name |
| departure_lat | double | Latitude |
| departure_lng | double | Longitude |
| destination_location | text | Ending point name |
| destination_lat | double | Latitude |
| destination_lng | double | Longitude |
| departure_date | date | Travel date |
| departure_time | time | Departure time |
| trip_status | text | Upcoming/In Progress/Completed/Cancelled |
| available_capacity | integer | Max requests (default: 5) |
| current_requests | integer | Accepted requests |
| base_fee | decimal | Base service fee |
| total_earnings | decimal | Total earned |
| notes | text | Additional info |
| route_polyline | text | Encoded route path |
| created_at | timestamptz | Creation timestamp |
| updated_at | timestamptz | Last update timestamp |

---

## 🚀 Next Steps for Requesters

With trips now being logged, you can implement:

1. **Trip Search for Requesters**:
   - Search by departure/destination
   - Filter by date range
   - View available capacity

2. **Request System**:
   - Pabakal (buy & deliver) requests
   - Pasabay (carry package) requests
   - Request approval workflow

3. **Live Tracking**:
   - Real-time location updates
   - ETA calculation
   - Route progress visualization

---

## 🐛 Troubleshooting

### Issue: Google Maps not showing

**Solution**:
1. Verify API key is correctly added
2. Check API is enabled in Google Cloud Console
3. Ensure billing is enabled (Google requires it even for free tier)
4. Restart the app after configuration

### Issue: Location search not working

**Solution**:
1. Check Geocoding API is enabled
2. Verify internet connection
3. Check API key restrictions
4. Ensure location permissions are granted

### Issue: Trip not saving to database

**Solution**:
1. Verify SQL schema was run correctly
2. Check RLS policies are active
3. Ensure user is authenticated
4. Check Supabase logs for errors
5. Verify user account is verified

### Issue: Statistics not updating

**Solution**:
1. Verify `get_trip_stats` function exists
2. Check function permissions (`GRANT EXECUTE`)
3. Restart app to refresh data
4. Check Supabase function logs

---

## 📞 Support

For issues or questions:
1. Check Supabase logs (Dashboard → Logs)
2. Check Flutter console for errors
3. Verify all setup steps were completed
4. Test with sample data first

---

## ✅ Checklist

Before testing, ensure:

- [ ] Supabase `trips` table created
- [ ] RLS policies active
- [ ] `get_trip_stats()` function exists
- [ ] Google Maps API key obtained
- [ ] Android manifest updated
- [ ] iOS Info.plist updated
- [ ] Dependencies installed (`flutter pub get`)
- [ ] App rebuilt after configuration
- [ ] User account verified
- [ ] Location permissions granted

---

## 🎉 Success Indicators

You'll know everything is working when:
- ✅ Map loads on home page
- ✅ Location search shows suggestions
- ✅ Markers appear when locations selected
- ✅ Date/time pickers work
- ✅ Trip registration succeeds
- ✅ Statistics update automatically
- ✅ Data appears in Supabase dashboard

---

**Happy Coding! 🚀**

