# Pasabay Verifier System - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PASABAY PROJECT                               │
│                     (Single Flutter Codebase)                        │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
         ┌──────────▼──────────┐     ┌─────────▼──────────┐
         │  main_traveler.dart │     │ main_verifier.dart │
         │   (Mobile Entry)    │     │   (Web Entry)      │
         └──────────┬──────────┘     └─────────┬──────────┘
                    │                           │
         ┌──────────▼──────────┐     ┌─────────▼──────────┐
         │   TRAVELER APP      │     │ VERIFIER DASHBOARD │
         │   📱 Mobile Only     │     │  🖥️ Web Only       │
         └──────────┬──────────┘     └─────────┬──────────┘
                    │                           │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    SHARED COMPONENTS      │
                    │  - Models                 │
                    │  - Services               │
                    │  - Utils                  │
                    │  - Constants              │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │    SUPABASE BACKEND       │
                    │  - Authentication         │
                    │  - Database (PostgreSQL)  │
                    │  - Storage                │
                    │  - Row Level Security     │
                    └───────────────────────────┘
```

## User Flow Diagram

```
┌─────────────────┐                    ┌──────────────────┐
│   TRAVELER      │                    │   VERIFIER       │
│   (Mobile App)  │                    │  (Web Dashboard) │
└────────┬────────┘                    └────────┬─────────┘
         │                                      │
         │ 1. Sign Up/Login                    │
         ├──────────────────────────────────────┤
         │                                      │
         │ 2. Navigate to                       │
         │    Identity Verification             │
         │                                      │
         │ 3. Upload Documents                  │
         │    - Government ID                   │
         │    - Selfie                          │
         │                                      │
         │ 4. Submit Request                    │
         ├─────────────────────┐                │
         │                     │                │
         │        ┌────────────▼────────────┐   │
         │        │  SUPABASE DATABASE      │   │
         │        │  Status: PENDING        │   │
         │        └────────────┬────────────┘   │
         │                     │                │
         │                     │ 5. Query       │
         │                     │    Requests    │
         │                     └───────────────►│
         │                                      │
         │                     6. View Request  │
         │                        Details       │
         │                                      │
         │                     7. Review        │
         │                        Documents     │
         │                                      │
         │                     8. Decision      │
         │                        (Approve/     │
         │                         Reject)      │
         │                                      │
         │        ┌─────────────────────────┐   │
         │        │  SUPABASE DATABASE      │   │
         │        │  Status: APPROVED or    │   │
         │        │          REJECTED       │   │
         │        └────────────┬────────────┘   │
         │                     │                │
         │ 9. Notification     │                │
         │    (Status Update)  │                │
         ◄─────────────────────┘                │
         │                                      │
         │ 10. View Status                      │
         │     - Approved ✓                     │
         │     - Rejected ✗                     │
         │                                      │
```

## Data Model

```
┌─────────────────────────────────────┐
│            USERS TABLE              │
├─────────────────────────────────────┤
│ id (UUID) PK                        │
│ email (TEXT)                        │
│ role (ENUM)                         │
│   - TRAVELER                        │
│   - REQUESTER                       │
│   - VERIFIER ◄──────────────┐       │
│   - ADMIN                    │       │
│ is_verified (BOOLEAN)        │       │
│ verified_at (TIMESTAMP)      │       │
│ created_at (TIMESTAMP)       │       │
└──────────────────┬──────────────────┘
                   │
                   │ FK: traveler_id
                   │
┌──────────────────▼──────────────────────────┐
│      VERIFICATION_REQUESTS TABLE            │
├─────────────────────────────────────────────┤
│ id (UUID) PK                                │
│ traveler_id (UUID) FK ──► users.id          │
│ traveler_name (TEXT)                        │
│ traveler_email (TEXT)                       │
│ documents (JSONB)                           │
│   {                                         │
│     "government_id": "url",                 │
│     "selfie": "url"                         │
│   }                                         │
│ status (ENUM)                               │
│   - PENDING                                 │
│   - UNDER_REVIEW                            │
│   - APPROVED                                │
│   - REJECTED                                │
│   - RESUBMITTED                             │
│ verifier_id (UUID) FK ──► users.id          │
│ verifier_name (TEXT)                        │
│ submitted_at (TIMESTAMP)                    │
│ reviewed_at (TIMESTAMP)                     │
│ rejection_reason (TEXT)                     │
│ verifier_notes (TEXT)                       │
└─────────────────────────────────────────────┘
```

## Access Control Matrix

```
┌──────────────┬──────────┬──────────┬──────────┬──────────┐
│   Resource   │ Traveler │ Requester│ Verifier │  Admin   │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Submit       │    ✓     │    ✓     │    ✗     │    ✓     │
│ Verification │          │          │          │          │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ View Own     │    ✓     │    ✓     │    ✗     │    ✓     │
│ Requests     │          │          │          │          │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ View All     │    ✗     │    ✗     │    ✓     │    ✓     │
│ Requests     │          │          │          │          │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Approve/     │    ✗     │    ✗     │    ✓     │    ✓     │
│ Reject       │          │          │          │          │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Verifier     │    ✗     │    ✗     │    ✓     │    ✓     │
│ Dashboard    │          │          │          │          │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Mobile App   │    ✓     │    ✓     │    ✗     │    ✗     │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Web Dashboard│    ✗     │    ✗     │    ✓     │    ✓     │
└──────────────┴──────────┴──────────┴──────────┴──────────┘
```

## Platform Restrictions

```
┌──────────────────────────────────────────────────────┐
│                   TRAVELER APP                       │
├──────────────────────────────────────────────────────┤
│  Allowed: Android, iOS                               │
│  Blocked: Web                                        │
│                                                      │
│  if (kIsWeb) {                                       │
│    return "Mobile Only" screen;                      │
│  }                                                   │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│               VERIFIER DASHBOARD                      │
├──────────────────────────────────────────────────────┤
│  Allowed: Web (Chrome, Firefox, Edge, Safari)        │
│  Blocked: Mobile (Android, iOS)                      │
│                                                      │
│  if (!kIsWeb) {                                      │
│    return "Web Only" screen;                         │
│  }                                                   │
└──────────────────────────────────────────────────────┘
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│                 DEVELOPMENT                         │
├─────────────────────────────────────────────────────┤
│  flutter run -t lib/main_traveler.dart -d chrome   │
│  flutter run -t lib/main_verifier.dart -d chrome   │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                 BUILD PROCESS                       │
├─────────────────────────────────────────────────────┤
│  Traveler: flutter build apk                        │
│  Verifier: flutter build web                        │
└────────────┬────────────────────────┬───────────────┘
             │                        │
    ┌────────▼────────┐    ┌─────────▼──────────┐
    │   MOBILE APK    │    │    WEB BUILD       │
    │   Android/iOS   │    │   HTML/JS/CSS      │
    └────────┬────────┘    └─────────┬──────────┘
             │                        │
    ┌────────▼────────┐    ┌─────────▼──────────┐
    │  GOOGLE PLAY    │    │  WEB HOSTING       │
    │  APP STORE      │    │  - Netlify         │
    │                 │    │  - Vercel          │
    │                 │    │  - Firebase        │
    └─────────────────┘    └────────────────────┘
```

## Security Layers

```
┌─────────────────────────────────────────────────┐
│         LAYER 1: PLATFORM RESTRICTION           │
│  (Flutter kIsWeb check - prevents wrong access) │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│         LAYER 2: AUTHENTICATION                 │
│  (Supabase Auth - validates user identity)      │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│         LAYER 3: ROLE VALIDATION                │
│  (Check user.role in database)                  │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│         LAYER 4: ROW LEVEL SECURITY             │
│  (Supabase RLS - database enforced permissions) │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│         LAYER 5: API VALIDATION                 │
│  (Service layer checks before operations)       │
└─────────────────────────────────────────────────┘
```

## State Management Flow

```
┌─────────────────┐
│  User Action    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  Widget (UI Layer)          │
│  - Buttons                  │
│  - Forms                    │
│  - Displays                 │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Service Layer              │
│  - AuthService              │
│  - VerificationService      │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Supabase Client            │
│  - API Calls                │
│  - Real-time Updates        │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Supabase Backend           │
│  - Database                 │
│  - Storage                  │
│  - Auth                     │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Response                   │
│  - Success/Error            │
│  - Data                     │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  UI Update                  │
│  - setState()               │
│  - Show Snackbar            │
│  - Navigate                 │
└─────────────────────────────┘
```

---

**Visual Guide Complete** 🎨
