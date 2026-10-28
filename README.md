# IIECM Admin — Complete Admin Application

A professional, mobile-first admin application for the **International Institute of E-commerce and Management (IIECM)**. Built with React, TypeScript, Vite, Tailwind CSS, and Capacitor for Android packaging.

## Features

- **Dashboard** — Summary cards, enrolment/payment charts, recent registrations, upcoming classes, activity feed, quick actions
- **Student Management** — Searchable/filterable list, add/edit forms with validation, detailed profile with tabs (overview, courses, assessments, payments, career guidance)
- **Instructor Management** — Directory with cards, add/edit forms, course assignments, class schedules, activity summaries
- **Course Management** — Course list, create/edit, course details with modules & lessons, enrolment tracking, live class schedules, publish/draft/archive states
- **Payments & Subscriptions** — Transaction list, payment detail view, approve/reject with reasons, receipt printing, CSV export, subscription tracking
- **Enquiries & Counselling** — Enquiry list with filters, detailed view, follow-up history, convert to student, new enquiry creation
- **Assessments** — Assessment list, categories, question bank, assessment results, create new assessments
- **Career Guidance** — Appointments tracking, career action plans with milestones
- **Resources** — Study materials, career resources, government exam prep, visibility controls, CSV export
- **Notifications** — Notification center with read/unread, mark all read, type/priority badges
- **Reports** — 8 report types with date filters and CSV export, charts and summary
- **Settings** — Institute profile, course categories, subscription plans, notification preferences, app info, privacy & security

## Tech Stack

- React 18 + TypeScript
- Vite 7 (build tool)
- Tailwind CSS 3 (styling)
- React Router 6 (navigation)
- Recharts (dashboard charts)
- Lucide React (icons)
- Supabase JS client (auth & data — prepared, not yet connected)
- Capacitor 6 (Android packaging)

## Getting Started

### Prerequisites

- Node.js 18+
- npm 10+

### Installation

```bash
npm install
npm run dev
```

The dev server starts automatically. Open the provided URL in your browser.

### Demo Mode

The app runs in **demo mode** when Supabase credentials are not configured. Demo credentials:

- **Email:** `admin@iiecm.org`
- **Password:** `admin123`

Demo mode uses in-memory mock data. All navigation, search, filters, forms, pagination, and CRUD operations work against this mock data. Changes are lost on page refresh.

### Production Setup

1. Copy `.env.example` to `.env`
2. Fill in your Supabase project URL and anon key
3. The app will automatically use Supabase Auth when credentials are present

## Build

```bash
npm run build
```

This generates the `dist/` directory for production deployment.

## Type Checking

```bash
npm run typecheck
```

## Android (Capacitor)

### First-time setup

```bash
npm run build
npx cap add android
npx cap sync android
npx cap open android
```

### Subsequent builds

```bash
npm run build
npx cap sync android
npx cap open android
```

The Android project opens in Android Studio. Use a Pixel 8 emulator to test.

### Capacitor Configuration

The Capacitor config is in `capacitor.config.ts`:
- App ID: `com.iiecm.admin`
- App Name: `IIECM Admin`
- Web directory: `dist`

## Project Structure

```
src/
  app/
    router.tsx          # Route definitions with protected routes
  components/
    layout/             # AppLayout, Sidebar, Header, BottomNav
    navigation/         # Logo, nav-config
    tables/             # DataTable
    ui/                 # Card, Badge, Modal, FormField, Pagination, etc.
  features/
    auth/               # Login, Forgot/Reset Password, Profile
    dashboard/          # Dashboard
    students/           # Student list, add, profile
    instructors/        # Instructor directory
    courses/            # Course list, detail
    payments/           # Payment list, detail
    enquiries/          # Enquiry list, detail
    assessments/        # Assessment list, results, questions
    career-guidance/    # Appointments, action plans
    resources/          # Resource list
    notifications/      # Notification center
    reports/            # Reports with CSV export
    settings/           # Settings
    more/               # Mobile "More" navigation hub
  hooks/                # useAuth, useMockStore
  services/
    supabase/           # client.ts, auth.ts (prepared for real integration)
  types/                # All TypeScript interfaces
  utils/                # Utilities + permissions
  mock-data/            # Mock data source + reactive store
```

## Roles and Permissions

The app includes a permission system for four roles:
- **Super Admin** — Full access including admin management
- **Administrator** — Full access except admin management
- **Instructor** — Limited to courses, students, assessments
- **Student** — Limited to dashboard, courses, notifications

Client-side permission checks control navigation visibility. **Production authorization must be enforced through Supabase Row Level Security policies.**

## Unfinished Backend Integrations

The following require real backend integration before production use:

### 1. Authentication
- Supabase Auth integration is prepared in `services/supabase/auth.ts`
- Currently uses demo mode with hardcoded credentials
- **Required:** Create admin users in Supabase Auth, set up user metadata for roles

### 2. Database Tables

Required tables for full functionality:

| Table | Purpose |
|-------|---------|
| `admins` | Admin user profiles with roles |
| `students` | Student records |
| `instructors` | Instructor records |
| `courses` | Course catalog |
| `course_modules` | Course modules |
| `course_lessons` | Lessons within modules |
| `course_categories` | Course categories |
| `payments` | Payment transactions |
| `subscriptions` | Subscription plans and active subscriptions |
| `enquiries` | Student enquiries |
| `enquiry_followups` | Follow-up history |
| `assessments` | Assessment definitions |
| `assessment_categories` | Assessment categories |
| `questions` | Question bank |
| `assessment_results` | Student assessment results |
| `career_appointments` | Career guidance appointments |
| `career_action_plans` | Student career plans |
| `resources` | Study materials and resources |
| `notifications` | In-app notifications |
| `activity_logs` | Admin activity audit trail |
| `live_classes` | Scheduled live sessions |

### 3. Row Level Security
- All tables must have RLS enabled
- Policies must enforce ownership and role-based access
- Use `auth.uid()` for ownership checks

### 4. Payment Integration
- Razorpay integration requires server-side payment verification
- Webhook handling for payment status updates
- **Never** mark payments as verified based on frontend callbacks alone

### 5. File Storage
- Resource file uploads require Supabase Storage buckets
- Student resume uploads require private bucket with access policies

### 6. Push Notifications
- Notification center is UI-only
- Requires push notification service integration (FCM for Android)

### 7. Video Streaming
- Live class and recorded session integration points are prepared
- Requires a video streaming service (e.g., Zoom, Jitsi, or custom WebRTC)

## Important Notes

- This is a **frontend prototype** with demo mode. Do not use demo credentials as production authentication.
- All mock data is in-memory and resets on page refresh.
- The Supabase client is initialized but no database migrations have been applied.
- No secrets or API keys are exposed in frontend environment variables.
- CSV export produces valid downloadable files.
- All destructive actions require confirmation dialogs.
