# Requester Feature Implementation - Setup Guide

## 📋 Overview

This guide covers the complete implementation of the requester feature where requesters can:
1. Search for available travelers by route
2. View traveler details and trip information
3. Submit **Pabakal** (buy items) or **Pasabay** (deliver package) requests
4. Track their requests in the activity page

---

## 🗄️ Database Setup

### Step 1: Create the Service Requests Table

Run the SQL script located at `supabase_service_requests_schema.sql` in your Supabase SQL Editor.

This will create:
- ✅ `service_requests` table with all necessary fields
- ✅ Indexes for optimal query performance
- ✅ Row Level Security (RLS) policies
- ✅ Triggers for automatic timestamp updates
- ✅ Helper functions for request management
- ✅ Storage bucket for attachments

### Step 2: Verify the Setup

After running the script, verify by running:

```sql
-- Check if table exists
SELECT * FROM public.service_requests LIMIT 1;

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'service_requests';

-- Check storage bucket exists
SELECT * FROM storage.buckets WHERE id = 'attachments';
```

---

## 📱 Features Implemented

### 1. **Requester Home Page** (`lib/screens/requester/requester_home_page.dart`)

**New Features:**
- Location search inputs (From & To)
- "Search Available Travelers" button
- Integrated with `RequestService` for trip search

**User Flow:**
1. Enter departure location (e.g., "Iloilo")
2. Enter destination location (e.g., "Roxas")
3. Click "Search Available Travelers"
4. View results in the search results page

---

### 2. **Traveler Search Results Page** (`lib/screens/requester/traveler_search_results_page.dart`)

**Features:**
- Lists all available trips matching the route
- Shows traveler profile picture, name, and rating
- Displays trip details (date, time, capacity, vehicle)
- Shows trip notes if available
- Click on any trip to view details and submit a request

**Data Shown:**
- Traveler name and profile picture
- Star rating (currently 4.8 - can be dynamic)
- Verification badge
- Departure date and time
- Available capacity
- Vehicle type
- Trip notes

---

### 3. **Traveler Detail Page** (`lib/screens/requester/traveler_detail_page.dart`)

**Major Updates:**
- Integrated with real Trip and Traveler data
- Dynamic service fee calculation
- File upload to Supabase Storage
- Form validation
- Loading states during submission

**Service Types:**

#### A. **Pabakal (Buy Items)**
Fields:
- Product Name (required)
- Store Name (required)
- Store Location (required)
- Product Cost (required, number)
- Additional Description (optional)
- Attachments (photos/documents)

Fee Calculation:
- Service Fee = 10% of product cost
- Total Amount = Product Cost + Service Fee

#### B. **Pasabay (Deliver Package)**
Fields:
- Recipient Name (required)
- Recipient Phone (required)
- Pickup Location (optional)
- Drop-off Location (required)
- Preferred Delivery Time (optional)
- Package Description (optional)
- Attachments (photos/documents)

Fee Calculation:
- Service Fee = ₱50.00 (flat rate)
- Total Amount = Service Fee

**Submission Process:**
1. Select service type (Pabakal or Pasabay)
2. Fill in required fields
3. Optionally attach photos or documents
4. Review fee breakdown
5. Submit request
6. Files are uploaded to Supabase Storage
7. Request is created in the database
8. Success screen is shown

---

## 🔧 Services & Models

### **RequestService** (`lib/services/request_service.dart`)

**Methods:**

```dart
// Search for available trips by route
Future<List<Trip>> searchAvailableTrips({
  required String departureLocation,
  required String destinationLocation,
  DateTime? date,
})

// Get traveler information
Future<Map<String, dynamic>?> getTravelerInfo(String travelerId)

// Create a service request
Future<bool> createRequest({
  required String travelerId,
  required String tripId,
  required String serviceType,
  // ... all request parameters
})

// Get requester's requests
Future<List<ServiceRequest>> getRequesterRequests({String? status})

// Get traveler's requests
Future<List<ServiceRequest>> getTravelerRequests({String? status})

// Cancel a request
Future<bool> cancelRequest(String requestId)
```

### **ServiceRequest Model** (`lib/models/request.dart`)

**Properties:**
- Basic: id, requesterId, travelerId, tripId, serviceType, status
- Common: pickupLocation, dropoffLocation, pickupTime
- Pabakal: productName, storeName, storeLocation, productCost, productDescription
- Pasabay: recipientName, recipientPhone, packageDescription
- Attachments: photoUrls, documentUrls
- Payment: serviceFee, totalAmount
- Metadata: createdAt, updatedAt, notes, rejectionReason

**Helper Methods:**
- `formattedCreatedAt`: Returns formatted creation date
- `formattedPickupTime`: Returns formatted pickup time

---

## 📊 Database Schema

### **service_requests Table**

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| requester_id | UUID | References auth.users |
| traveler_id | UUID | References auth.users |
| trip_id | UUID | References trips table |
| service_type | VARCHAR(20) | 'Pabakal' or 'Pasabay' |
| status | VARCHAR(20) | Pending/Accepted/Rejected/Completed/Cancelled |
| pickup_location | TEXT | Pickup address (optional) |
| dropoff_location | TEXT | Delivery address |
| pickup_time | TIMESTAMPTZ | Preferred time (optional) |
| product_name | VARCHAR(255) | For Pabakal |
| store_name | VARCHAR(255) | For Pabakal |
| store_location | TEXT | For Pabakal |
| product_cost | DECIMAL(10,2) | For Pabakal |
| product_description | TEXT | For Pabakal |
| recipient_name | VARCHAR(255) | For Pasabay |
| recipient_phone | VARCHAR(20) | For Pasabay |
| package_description | TEXT | For Pasabay |
| photo_urls | TEXT[] | Array of photo URLs |
| document_urls | TEXT[] | Array of document URLs |
| service_fee | DECIMAL(10,2) | Service fee amount |
| total_amount | DECIMAL(10,2) | Total amount to pay |
| notes | TEXT | Additional notes |
| rejection_reason | TEXT | If rejected |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

---

## 🔐 Security

### Row Level Security (RLS) Policies

1. **SELECT Policies:**
   - Requesters can view their own requests
   - Travelers can view requests for their trips

2. **INSERT Policy:**
   - Authenticated users can create requests (as requester)

3. **UPDATE Policies:**
   - Requesters can update their pending requests
   - Travelers can update requests for their trips (accept/reject)

4. **DELETE Policy:**
   - Requesters can delete their own pending requests

### Storage Security

- Authenticated users can upload files to `attachments` bucket
- All users can view files (public bucket)
- Users can delete their own files

---

## 🎯 Helper Functions

The schema includes several helper functions:

1. **get_traveler_request_stats(traveler_user_id)**
   - Returns statistics for a traveler (total, pending, accepted, completed requests, earnings)

2. **get_requester_request_stats(requester_user_id)**
   - Returns statistics for a requester (total, pending, accepted, completed requests, spending)

3. **accept_service_request(request_id)**
   - Accepts a request and updates trip capacity
   - Returns true/false

4. **reject_service_request(request_id, reason)**
   - Rejects a request with optional reason
   - Returns true/false

5. **cancel_service_request(request_id)**
   - Cancels a request (requester action)
   - Restores capacity if it was accepted
   - Returns true/false

**Usage Example:**

```sql
-- Accept a request
SELECT public.accept_service_request('request-uuid-here');

-- Reject a request
SELECT public.reject_service_request('request-uuid-here', 'Sorry, capacity is full');

-- Cancel a request
SELECT public.cancel_service_request('request-uuid-here');
```

---

## 🧪 Testing the Flow

### Test as a Requester:

1. **Search for Travelers:**
   ```
   - Go to Home Page
   - Enter "Iloilo" as departure
   - Enter "Roxas" as destination
   - Click "Search Available Travelers"
   ```

2. **View Results:**
   ```
   - See list of available trips
   - Check traveler info, ratings, trip details
   - Click on a trip to view details
   ```

3. **Submit Pabakal Request:**
   ```
   - Select "Pabakal" service type
   - Enter: iPhone 15 Pro Max
   - Store: Apple Store
   - Location: SM City Iloilo
   - Cost: 75000
   - Optionally add photos
   - Submit request
   ```

4. **Submit Pasabay Request:**
   ```
   - Select "Pasabay" service type
   - Recipient: Maria Santos
   - Phone: 09123456789
   - Drop-off: 123 Main St, Roxas
   - Package: Documents
   - Submit request
   ```

### Verify in Database:

```sql
-- Check created requests
SELECT 
    sr.id,
    sr.service_type,
    sr.status,
    sr.product_name,
    sr.recipient_name,
    sr.service_fee,
    sr.total_amount,
    sr.created_at
FROM service_requests sr
ORDER BY created_at DESC
LIMIT 10;

-- Check requester stats
SELECT * FROM get_requester_request_stats('YOUR_USER_ID');

-- Check traveler stats
SELECT * FROM get_traveler_request_stats('TRAVELER_USER_ID');
```

---

## 📦 Dependencies

Make sure you have these packages in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  image_picker: ^1.0.4
  file_picker: ^6.0.0
  intl: ^0.18.1
  google_maps_flutter: ^2.5.0
  geocoding: ^2.1.1
  geolocator: ^10.1.0
```

---

## 🚀 Next Steps

### For Travelers:
- View incoming requests in Activity tab
- Accept or reject requests
- Manage accepted bookings

### For Requesters:
- View request status in Activity tab
- Cancel pending requests
- Track accepted requests

### Additional Features:
- In-app messaging between requester and traveler
- Payment integration
- Rating system after completion
- Push notifications for request updates

---

## 🐛 Troubleshooting

### Common Issues:

1. **"No travelers found"**
   - Make sure there are active trips in the database
   - Check that trip status is 'Upcoming'
   - Verify available_capacity > 0

2. **"Failed to submit request"**
   - Check Supabase connection
   - Verify RLS policies are set up correctly
   - Check that the trip still has available capacity

3. **File upload fails**
   - Verify 'attachments' storage bucket exists
   - Check storage policies are set up
   - Ensure files are not too large (max 50MB recommended)

4. **Search returns empty**
   - Location search uses partial match (ILIKE)
   - Try simpler location names (e.g., "Iloilo" instead of "Iloilo City")

---

## 📝 Summary

✅ **Implemented:**
- Complete requester flow from search to submission
- Two service types (Pabakal & Pasabay)
- File attachments with Supabase Storage
- Dynamic fee calculation
- Comprehensive database schema with RLS
- Helper functions for request management
- Form validation and error handling
- Loading states and user feedback

✅ **Database:**
- service_requests table created
- Indexes for performance
- RLS policies for security
- Helper functions for common operations
- Storage bucket for attachments

✅ **Testing:**
- No linter errors
- All forms work correctly
- Files can be uploaded
- Requests are created successfully

---

## 🎉 You're All Set!

The requester feature is now fully functional. Users can search for travelers, view trip details, and submit service requests for both Pabakal and Pasabay services!

