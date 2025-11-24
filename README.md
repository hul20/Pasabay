# Pasabay - Community Marketplace App

Pasabay is a Flutter-based community marketplace app that connects travelers with people who need deliveries. It features a dual-entry-point architecture with separate interfaces for regular users (travelers/requesters) and verification staff.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (latest stable version)
- Supabase account
- Android Studio / Xcode (for mobile development)

### Installation
```bash
# Clone the repository
git clone https://github.com/hul20/Pasabay.git

# Navigate to project directory
cd pasabay_app

# Install dependencies
flutter pub get

# Run the app
flutter run lib/main.dart      # For travelers/requesters
flutter run lib/verifier.dart  # For verifiers
```

## 📱 Architecture

### Dual Entry Points
- **main.dart** - Regular users (travelers and requesters)
- **verifier.dart** - Verification staff only

### Key Features
- ✅ Identity verification system with document upload
- ✅ Role-based authentication (Traveler, Requester, Verifier, Admin)
- ✅ Supabase backend with RLS policies
- ✅ Real-time verification request management
- ✅ Document storage using Supabase Storage

## 🔐 User Roles

### Title Case Format (Database Constraint)
All roles must be in Title Case:
- `Traveler` - Users who travel and can deliver items
- `Requester` - Users who need items delivered
- `Verifier` - Staff who verify user identities

## 📚 Documentation

### Essential Guides
1. **[VERIFIER_INTEGRATION_COMPLETE.md](VERIFIER_INTEGRATION_COMPLETE.md)** - Complete verifier system setup and testing guide
2. **[SUPABASE_GUIDE.md](SUPABASE_GUIDE.md)** - Database setup and configuration

## 🗄️ Database Setup

Run the SQL migrations in your Supabase SQL Editor:

```sql
-- 1. Setup users table with role constraint
-- See: migrations/add_identity_verification.sql

-- 2. Setup verification_requests table
-- See: migrations/setup_verification_requests_complete.sql
```

### Key Tables
- **users** - User accounts with roles and verification status
- **verification_requests** - Identity verification submissions with documents

### RLS Policies
- Users can view/insert their own verification requests
- Verifiers can view/update all verification requests
- Status values use Title Case: 'Pending', 'Approved', 'Rejected'

## 🧪 Testing

### Test as Traveler
```powershell
flutter run lib/main.dart
```
1. Sign up as new user
2. Navigate to Identity Verification
3. Upload Government ID and Selfie
4. Submit verification request

### Test as Verifier
```powershell
flutter run lib/verifier.dart
```
**Verifier Account:**
- Email: `frogjump002@gmail.com`
- Password: [your password]
- Role: `Verifier`

**Dashboard Features:**
- View all verification requests
- Filter by status (Pending, Under Review, Approved, Rejected)
- Approve/reject requests with notes
- View uploaded documents

## 📁 Project Structure

```
lib/
├── main.dart                 # Entry point for travelers/requesters
├── verifier.dart            # Entry point for verifiers
├── models/                  # Data models
│   ├── user_role.dart      # Role enum with Title Case
│   ├── verification_status.dart
│   └── verification_request.dart
├── screens/                 # Traveler screens
│   └── traveler/           # Verification flow screens
├── services/               # Business logic
│   ├── auth_service.dart   # Authentication
│   └── verification_service.dart  # Verifier operations
├── utils/
│   └── supabase_service.dart  # Traveler operations
├── verifier/               # Verifier-only screens
│   └── screens/
│       ├── verifier_login_screen.dart
│       ├── verifier_dashboard_screen.dart
│       └── verification_detail_screen.dart
└── widgets/                # Reusable components

migrations/
├── add_identity_verification.sql
├── setup_verification_requests_complete.sql
└── setup_verifier_system.sql
```

## 🔧 Configuration

### Supabase Setup
1. Create a Supabase project
2. Run all migrations from `migrations/` folder
3. Update `lib/main.dart` with your Supabase credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

### Storage Buckets
Create these buckets in Supabase Storage:
- `verification_documents` - For government IDs and selfies
- Set appropriate RLS policies for access control

## 🎯 Key Workflows

### Identity Verification Flow
1. **Traveler Side:**
   - Upload Government ID → Supabase Storage
   - Upload Selfie → Supabase Storage
   - Submit verification request → `verification_requests` table
   - Status: 'Pending'

2. **Verifier Side:**
   - Login to verifier dashboard
   - View pending requests
   - Review documents
   - Approve/Reject with notes
   - Status updates: 'Under Review' → 'Approved' or 'Rejected'

### Data Flow
```
Traveler Upload → Storage URLs → SupabaseService.submitVerificationRequest()
                                          ↓
                                 verification_requests table
                                          ↓
                        VerificationService.getAllRequests()
                                          ↓
                              Verifier Dashboard Display
                                          ↓
                        Approve/Reject → Status Update
```

## 🛠️ Development Notes

### Status Value Format
Always use Title Case for status values:
- Use `.dbValue` when writing to database
- Use `fromString()` when reading from database

```dart
// Writing to database
status: VerificationStatus.PENDING.dbValue  // → 'Pending'

// Reading from database
VerificationStatus.fromString('Pending')    // → PENDING enum
```

### Creating Verifier Accounts
Verifiers must be created by admins (no public signup):
```sql
-- In Supabase SQL Editor
INSERT INTO auth.users (email, encrypted_password, ...)
VALUES ('verifier@example.com', crypt('password', gen_salt('bf')), ...);

INSERT INTO public.users (id, email, role, ...)
VALUES ('[auth_user_id]', 'verifier@example.com', 'Verifier', ...);
```

## 🐛 Troubleshooting

### Verifier Dashboard Shows No Requests
1. Check if `verification_requests` table exists
2. Verify RLS policies are active
3. Confirm verifier role is exactly: `Verifier` (Title Case)
4. Check console for error messages

### Status Filter Not Working
1. Verify status values in database are Title Case
2. Check VerificationService uses `.dbValue` in queries
3. Confirm database CHECK constraint allows Title Case values

### Images Not Displaying
1. Check Storage bucket permissions
2. Verify files uploaded successfully
3. Check URL format is correct

See **[VERIFIER_INTEGRATION_COMPLETE.md](VERIFIER_INTEGRATION_COMPLETE.md)** for detailed troubleshooting.

## 📄 License

This project is licensed under the MIT License.

## 👥 Contributors

- Dallas - Initial development

## 📞 Support

For issues and questions:
- Check [VERIFIER_INTEGRATION_COMPLETE.md](VERIFIER_INTEGRATION_COMPLETE.md) for detailed guides
- Review [SUPABASE_GUIDE.md](SUPABASE_GUIDE.md) for database setup
- Open an issue on GitHub

