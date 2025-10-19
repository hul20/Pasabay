# Verifier Full-Screen Web Interface

## Overview
The Pasabay Verifier interface has been upgraded to a modern, full-screen web-based design optimized for desktop browsers.

## Features

### ✨ New Full-Screen Design
- **Split-screen Layout**: Professional two-panel design
  - **Left Panel** (>900px width): Branding with Pasabay logo, features list
  - **Right Panel**: Login/signup forms
- **Responsive**: Adapts to mobile, tablet, and desktop screens
- **Modern UI**: Elevated cards, gradient backgrounds, smooth animations

### 🔐 Authentication
- **Login Screen**: Email/password with role validation
- **No Signup Option**: Verifier accounts must be created by administrators via Supabase Dashboard
- **Security**: Role-based access control ensures only authorized verifiers can access the dashboard

### 🎨 Design Elements
- **Colors**: Pasabay blue gradient (#00AAF3 to #0083B0)
- **Typography**: Clean, professional font hierarchy
- **Spacing**: Consistent padding and margins
- **Icons**: Material Design icons throughout

## Running the Verifier App

### Method 1: PowerShell Command
```powershell
cd "c:\Users\Dallas\Documents\Dallas\Pasabay Android App\pasabay_app"
flutter run -d chrome --web-port 8081 --target lib/verifier.dart
```

### Method 2: VS Code Debug
1. Open VS Code
2. Press F5 or click Run > Start Debugging
3. Select "Web (verifier)" configuration

### Method 3: Direct URL (after running)
```
http://localhost:8081
```

## Testing Both Apps Simultaneously

### Main User App (Travelers & Requesters)
```powershell
# Terminal 1
flutter run -d chrome --web-port 8080 --target lib/main.dart
```
**URL**: http://localhost:8080

### Verifier App
```powershell
# Terminal 2
flutter run -d chrome --web-port 8081 --target lib/verifier.dart
```
**URL**: http://localhost:8081

## Login vs Signup

### Login Screen Features
- **Purpose**: Existing verifier authentication
- **Fields**: Email, Password
- **Security**: Role validation (verifiers only)
- **No Signup**: Verifiers must be created by administrators

### Creating Verifier Accounts (Admin Only)
Verifier accounts can only be created through Supabase Dashboard:

1. **Create Auth User**:
   - Go to Supabase Dashboard → Authentication → Users
   - Click "Add User"
   - Enter email and password
   - Enable "Auto Confirm User"

2. **Add to Users Table**:
   ```sql
   INSERT INTO users (id, email, role, full_name)
   VALUES (
     'USER_ID_FROM_AUTH',  -- Copy from auth.users
     'verifier@example.com',
     'VERIFIER',
     'Verifier Name'
   );
   ```

3. **Provide Credentials**:
   - Give the verifier their login email and password
   - They can sign in at: http://localhost:8082

For detailed instructions, see: [CREATE_VERIFIER_ACCOUNT.md](CREATE_VERIFIER_ACCOUNT.md)

## Responsive Breakpoints

### Desktop (>900px)
- Split-screen layout
- Left branding panel visible
- Maximum form width: 500px
- Large padding (48px)

### Tablet (600px - 900px)
- Single column layout
- No branding panel
- Logo shown in form header
- Medium padding (48px)

### Mobile (<600px)
- Single column layout
- Logo shown in form header
- Small padding (24px)
- Touch-optimized buttons

## Backend Integration

### Supabase Authentication
- Uses `AuthService` for all auth operations
- Email/password authentication
- Automatic email verification
- Role-based access control

### Database Updates
- Creates user in `users` table
- Sets `role = 'VERIFIER'`
- Stores `full_name`, `email`, `created_at`
- Enforces RLS policies

## User Flow

### Admin Creates Verifier Account
1. Admin goes to Supabase Dashboard
2. Creates auth user with email/password
3. Inserts user record with VERIFIER role
4. Provides credentials to verifier
5. Verifier receives login information

### Verifier Login
1. Verifier opens app at configured URL
2. Enters email and password
3. Clicks "Sign In"
4. System validates verifier role
5. Redirects to dashboard if authorized

### Role Validation
- If non-verifier attempts login:
  - Error: "Access denied. Verifier credentials required."
  - User signed out automatically
  - Must sign in with correct credentials

## Testing Checklist

### Visual Testing
- [ ] Branding panel shows on desktop (>900px)
- [ ] Layout responsive at all breakpoints
- [ ] Forms centered and properly spaced
- [ ] Buttons have hover effects
- [ ] Icons aligned with text
- [ ] Error messages display correctly

### Functional Testing
- [ ] Email validation works
- [ ] Password visibility toggle functions
- [ ] Login validates credentials
- [ ] Login checks verifier role
- [ ] Non-verifiers blocked from access
- [ ] No signup option visible (removed for security)
- [ ] Info message shows "Authorized Verifiers Only"
- [ ] Success/error messages display

### Cross-Browser Testing
- [ ] Chrome (primary)
- [ ] Firefox
- [ ] Edge
- [ ] Safari (if available)

## Known Limitations

1. **Email Verification**: Users must verify email via link before first login
2. **Password Reset**: Not yet implemented (future feature)
3. **Admin Approval**: All signups create verifiers (could add approval workflow)
4. **Profile Images**: Not yet implemented (future feature)

## Next Steps

### Planned Enhancements
1. Add password reset functionality
2. Implement "Remember Me" checkbox
3. Add social login (Google, Facebook)
4. Create admin approval workflow for new verifiers
5. Add profile image upload
6. Implement 2FA (Two-Factor Authentication)

## Troubleshooting

### Issue: "Access denied" error
- **Cause**: User doesn't have VERIFIER role
- **Solution**: Check database - user's role must be 'VERIFIER'

### Issue: Branding panel not showing
- **Cause**: Screen width < 900px
- **Solution**: Resize browser window or use desktop screen

### Issue: Form validation fails
- **Cause**: Missing or invalid data
- **Solution**: Check all fields meet requirements

### Issue: Signup succeeds but can't login
- **Cause**: Email not verified
- **Solution**: Check email for verification link

## File Structure
```
lib/
├── verifier.dart                          # Entry point
├── verifier/
│   └── screens/
│       ├── verifier_login_screen.dart     # Full-screen login UI (no signup)
│       ├── verifier_dashboard_screen.dart # Dashboard
│       └── verification_detail_screen.dart # Detail view
├── services/
│   └── auth_service.dart                  # Auth operations
└── models/
    └── user_role.dart                     # Role enum
```

## Design System

### Colors
- **Primary**: #00AAF3 (Pasabay Blue)
- **Secondary**: #0083B0 (Dark Blue)
- **Text Primary**: #1A1A1A
- **Text Secondary**: #666666
- **Error**: #D32F2F
- **Success**: #388E3C

### Typography
- **Heading**: 32px, Bold
- **Subheading**: 16-18px, Regular
- **Body**: 14-16px, Regular
- **Caption**: 12px, Regular

### Spacing
- **Large**: 48px
- **Medium**: 32px
- **Regular**: 24px
- **Small**: 16px
- **Tiny**: 8px

## Support
For issues or questions:
- Check database RLS policies
- Verify Supabase connection
- Review console logs for errors
- Test with different screen sizes

---

**Last Updated**: 2024
**Version**: 2.0 (Full-Screen Web Interface)
