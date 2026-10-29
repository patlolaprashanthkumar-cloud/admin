-- Migration: 20261028000002_create_students_instructors.sql
-- Description: Students and Instructors tables with constraints, indexes, and RLS

-- Subscription Plan Type
DO $$ BEGIN
  CREATE TYPE subscription_plan AS ENUM ('free', 'basic', 'premium', 'enterprise');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Subscription Status Type
DO $$ BEGIN
  CREATE TYPE subscription_status AS ENUM ('active', 'expired', 'pending', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Career Guidance Status Type
DO $$ BEGIN
  CREATE TYPE career_guidance_status AS ENUM ('not_started', 'in_progress', 'completed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Instructors Table
CREATE TABLE IF NOT EXISTS public.instructors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  qualifications TEXT NOT NULL DEFAULT 'N/A',
  specialization TEXT NOT NULL,
  experience_years INTEGER NOT NULL DEFAULT 0 CHECK (experience_years >= 0),
  account_status account_status NOT NULL DEFAULT 'active',
  bio TEXT,
  rating NUMERIC(3,2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5),
  total_students INTEGER NOT NULL DEFAULT 0 CHECK (total_students >= 0),
  total_classes INTEGER NOT NULL DEFAULT 0 CHECK (total_classes >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger for instructors updated_at
DROP TRIGGER IF EXISTS trg_instructors_updated_at ON public.instructors;
CREATE TRIGGER trg_instructors_updated_at
  BEFORE UPDATE ON public.instructors
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Students Table
CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE SET NULL,
  student_id TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  education_level TEXT NOT NULL,
  qualification TEXT NOT NULL,
  preferred_category TEXT NOT NULL,
  subscription_plan subscription_plan NOT NULL DEFAULT 'basic',
  subscription_status subscription_status NOT NULL DEFAULT 'pending',
  subscription_start TIMESTAMPTZ,
  subscription_expiry TIMESTAMPTZ,
  account_status account_status NOT NULL DEFAULT 'active',
  resume_uploaded BOOLEAN NOT NULL DEFAULT FALSE,
  career_guidance_status career_guidance_status NOT NULL DEFAULT 'not_started',
  city TEXT,
  country TEXT NOT NULL DEFAULT 'India',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger for students updated_at
DROP TRIGGER IF EXISTS trg_students_updated_at ON public.students;
CREATE TRIGGER trg_students_updated_at
  BEFORE UPDATE ON public.students
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_students_email ON public.students(email);
CREATE INDEX IF NOT EXISTS idx_students_student_id ON public.students(student_id);
CREATE INDEX IF NOT EXISTS idx_students_account_status ON public.students(account_status);
CREATE INDEX IF NOT EXISTS idx_students_profile_id ON public.students(profile_id);

CREATE INDEX IF NOT EXISTS idx_instructors_email ON public.instructors(email);
CREATE INDEX IF NOT EXISTS idx_instructors_account_status ON public.instructors(account_status);
CREATE INDEX IF NOT EXISTS idx_instructors_profile_id ON public.instructors(profile_id);

-- Enable RLS
ALTER TABLE public.instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

-- Instructors Policies
CREATE POLICY "Public read for active instructors"
  ON public.instructors
  FOR SELECT
  TO authenticated, anon
  USING (account_status = 'active' OR public.is_admin_or_super());

CREATE POLICY "Instructors can edit own profile details"
  ON public.instructors
  FOR UPDATE
  TO authenticated
  USING (profile_id = auth.uid() OR public.is_admin_or_super())
  WITH CHECK (profile_id = auth.uid() OR public.is_admin_or_super());

CREATE POLICY "Admins have full access to instructors"
  ON public.instructors
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

-- Students Policies
CREATE POLICY "Admins have full access to students"
  ON public.students
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Students can view and update their own record"
  ON public.students
  FOR SELECT
  TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY "Students can update personal contact details"
  ON public.students
  FOR UPDATE
  TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

