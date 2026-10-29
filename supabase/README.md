# IIECM Admin — Supabase Backend Architecture & Integration Guide

This directory contains the production-ready Supabase backend structure for the **International Institute of E-commerce and Management (IIECM) Admin** portal.

---

## 1. Directory Structure

```
supabase/
├── config.toml                              # Supabase CLI project configuration
├── README.md                                # Comprehensive backend guide (this file)
├── migrations/                              # Ordered, timestamped SQL migrations
│   ├── 20261028000001_create_profiles.sql
│   ├── 20261028000002_create_students_instructors.sql
│   ├── 20261028000003_create_courses_and_enrollments.sql
│   ├── 20261028000004_create_payments_and_subscriptions.sql
│   ├── 20261028000005_create_enquiries_and_career_guidance.sql
│   ├── 20261028000006_create_assessments_and_results.sql
│   ├── 20261028000007_create_resources_notifications_classes.sql
│   └── 20261028000008_create_activity_logs.sql
└── functions/                               # Supabase Edge Functions (Deno TypeScript)
    ├── admin-create-user/index.ts           # Admin user & student/instructor provisioner
    ├── admin-update-user-role/index.ts      # Super Admin role update service
    ├── verify-payment/index.ts              # HMAC SHA-256 Razorpay payment verifier
    └── README.md                            # Edge Functions API specification
```

---

## 2. Database Tables & Entity Relationships

```
 auth.users
     │ (1:1)
 public.profiles
     ├── (1:1) public.students ─── (1:N) ─── public.course_enrollments ─── (N:1) ─── public.courses
     │                                                │                                     │
     │                                                ▼                                     │
     │                                     public.payments                                  │
     │                                                │                                     │
     └── (1:1) public.instructors ────────────────────┴─────────────────────────────────────┘
```

| Table | Purpose | Primary Key | Key Foreign Keys & Constraints |
|---|---|---|---|
| `profiles` | User profiles with role & contact info | `id` (UUID references `auth.users`) | `role`: `user_role` enum (`super_admin`, `admin`, `instructor`, `student`) |
| `students` | Institutional student records | `id` (UUID) | `profile_id` references `profiles(id)`, `student_id` (UNIQUE), `email` (UNIQUE) |
| `instructors` | Faculty & trainer profiles | `id` (UUID) | `profile_id` references `profiles(id)`, `email` (UNIQUE) |
| `course_categories` | Curriculum categories | `id` (UUID) | `name` (UNIQUE) |
| `courses` | Course catalog & syllabus | `id` (UUID) | `category_id`, `instructor_id` |
| `course_modules` | Modules within courses | `id` (UUID) | `course_id` references `courses(id)` ON DELETE CASCADE |
| `course_lessons` | Lessons inside modules | `id` (UUID) | `module_id` references `course_modules(id)` ON DELETE CASCADE |
| `course_enrollments` | Student course enrollments | `id` (UUID) | `UNIQUE(student_id, course_id)` (prevents duplicate enrollments) |
| `subscription_plans` | Available subscription tiers | `id` (`subscription_plan`) | `price`, `duration_months`, `features` |
| `student_subscriptions`| Active student subscriptions | `id` (UUID) | `student_id`, `plan` |
| `payments` | Transactions & receipts | `id` (UUID) | `transaction_ref` (UNIQUE), `student_id`, `course_id` |
| `enquiries` | Admissions CRM leads | `id` (UUID) | `enquiry_id` (UNIQUE), `email` |
| `enquiry_followups` | Lead counselling history | `id` (UUID) | `enquiry_id` references `enquiries(id)` ON DELETE CASCADE |
| `career_appointments` | Mentorship sessions | `id` (UUID) | `student_id` references `students(id)` ON DELETE CASCADE |
| `career_action_plans` | Milestone-based plans | `id` (UUID) | `student_id` (UNIQUE references `students(id)`) |
| `assessment_categories`| Testing topic classifications | `id` (UUID) | `name` (UNIQUE) |
| `questions` | Question bank | `id` (UUID) | `category_id` |
| `assessments` | Tests and examinations | `id` (UUID) | `category_id` |
| `assessment_questions`| Questions in an assessment | Composite PK | `(assessment_id, question_id)` |
| `assessment_course_assignments`| Courses mapped to assessment | Composite PK | `(assessment_id, course_id)` |
| `assessment_results` | Student score records | `id` (UUID) | `assessment_id`, `student_id` |
| `resources` | Downloadable study materials | `id` (UUID) | `visibility` (`public`, `enrolled`, `private`) |
| `notifications` | Notification center inbox | `id` (UUID) | `user_id` references `auth.users(id)` (NULL for broadcasts) |
| `live_classes` | Scheduled virtual lectures | `id` (UUID) | `course_id`, `instructor_id` |
| `activity_logs` | Immutable audit trail | `id` (UUID) | `admin_id` references `profiles(id)` |

---

## 3. Row Level Security (RLS) Policy Summary

| Table | Super Admin | Administrator | Instructor | Student |
|---|---|---|---|---|
| `profiles` | Full CRUD | Full CRUD (except altering other admin roles) | Read own profile, update non-role info | Read own profile, update non-role info |
| `students` | Full CRUD | Full CRUD | View students enrolled in assigned courses | View & update own record |
| `instructors` | Full CRUD | Full CRUD | Read active instructors, edit own bio | Read active instructors |
| `courses` | Full CRUD | Full CRUD | Read all published, update assigned courses | Read published courses |
| `enrollments`| Full CRUD | Full CRUD | View enrollments in assigned courses | View own enrollments |
| `payments` | Full CRUD | Full CRUD | No access | View own payments, insert pending proofs |
| `enquiries` | Full CRUD | Full CRUD | No access | Public insert for web leads |
| `assessments`| Full CRUD | Full CRUD | Create, edit and assign assessments | View active assessments for enrolled courses |
| `resources` | Full CRUD | Full CRUD | Upload and view all resources | View public and enrolled resources |
| `activity_logs` | Read & Append (Immutable) | Read & Append (Immutable) | No access | No access |

---

## 4. Setup & Deployment Guide

### Prerequisites
- Node.js 18+
- Supabase CLI installed (`npm install -g supabase` or `npx supabase`)
- Your own Supabase project created at [supabase.com](https://supabase.com)

### Step 1: Link Your Project
```bash
npx supabase login
npx supabase link --project-ref <your-supabase-project-id>
```

### Step 2: Apply Database Migrations
To push all 8 migrations to your remote Supabase project:
```bash
npx supabase db push
```

### Step 3: Deploy Edge Functions
Deploy the server-side functions with environment secrets:
```bash
# Set required secrets for payment verification
npx supabase secrets set RAZORPAY_KEY_ID="your_razorpay_key_id"
npx supabase secrets set RAZORPAY_KEY_SECRET="your_razorpay_secret"

# Deploy functions
npx supabase functions deploy admin-create-user
npx supabase functions deploy admin-update-user-role
npx supabase functions deploy verify-payment
```

---

## 5. Provisioning the Initial Super Admin

To create your initial Super Admin account securely:

1. Create a user via Supabase Dashboard Auth UI or SQL Editor:
```sql
-- Replace with your chosen admin email and a secure password:
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@iiecm.org',
  crypt('YourSuperAdminPassword123!', gen_salt('bf')),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Dr. Priya Sharma","role":"super_admin"}',
  NOW(),
  NOW()
);
```

2. Verify that the automatic trigger created the profile with `role = 'super_admin'`:
```sql
SELECT id, email, full_name, role FROM public.profiles WHERE email = 'admin@iiecm.org';
```

---

## 6. Frontend Integration Architecture

The frontend uses dual-mode architecture:
- **Demo Mode**: Active when `VITE_SUPABASE_URL` is omitted. Uses reactive `MockStore` with demo data for client walkthroughs.
- **Supabase Mode**: Active when `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are provided in `.env`.
- When Supabase credentials are configured, the frontend connects directly to Supabase Auth and the PostgreSQL database service layer. If credentials fail, it displays clear server authentication errors rather than silently falling back to mock mode.

