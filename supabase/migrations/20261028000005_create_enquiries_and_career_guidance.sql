-- Migration: 20261028000005_create_enquiries_and_career_guidance.sql
-- Description: Enquiry management CRM, follow-up history, and student career guidance

-- Enquiry Enums
DO $$ BEGIN
  CREATE TYPE enquiry_status AS ENUM ('new', 'contacted', 'follow_up', 'converted', 'closed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE enquiry_source AS ENUM ('website', 'referral', 'social_media', 'walk_in', 'phone', 'email');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE learning_mode AS ENUM ('online', 'offline', 'hybrid');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE follow_up_outcome AS ENUM ('no_response', 'interested', 'not_interested', 'callback_scheduled', 'converted');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE appointment_status AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE career_appointment_type AS ENUM ('career_guidance', 'resume_review', 'mock_interview', 'action_plan');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Enquiries Table
CREATE TABLE IF NOT EXISTS public.enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enquiry_id TEXT NOT NULL UNIQUE,
  student_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  education_level TEXT NOT NULL DEFAULT 'Not specified',
  career_interests TEXT[] NOT NULL DEFAULT '{}',
  preferred_service TEXT NOT NULL DEFAULT 'Basic Plan',
  budget_min NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  budget_max NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  preferred_mode learning_mode NOT NULL DEFAULT 'online',
  source enquiry_source NOT NULL DEFAULT 'website',
  assigned_counsellor TEXT NOT NULL DEFAULT 'Administrator',
  follow_up_date DATE,
  status enquiry_status NOT NULL DEFAULT 'new',
  notes TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_enquiries_updated_at ON public.enquiries;
CREATE TRIGGER trg_enquiries_updated_at
  BEFORE UPDATE ON public.enquiries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enquiry Follow-ups Table
CREATE TABLE IF NOT EXISTS public.enquiry_followups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enquiry_id UUID NOT NULL REFERENCES public.enquiries(id) ON DELETE CASCADE,
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  note TEXT NOT NULL,
  by_counsellor TEXT NOT NULL,
  outcome follow_up_outcome NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Career Guidance Appointments Table
CREATE TABLE IF NOT EXISTS public.career_appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  counsellor TEXT NOT NULL,
  type career_appointment_type NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  status appointment_status NOT NULL DEFAULT 'scheduled',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_career_appointments_updated_at ON public.career_appointments;
CREATE TRIGGER trg_career_appointments_updated_at
  BEFORE UPDATE ON public.career_appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Career Action Plans Table
CREATE TABLE IF NOT EXISTS public.career_action_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID UNIQUE NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  goals TEXT[] NOT NULL DEFAULT '{}',
  milestones JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_career_action_plans_updated_at ON public.career_action_plans;
CREATE TRIGGER trg_career_action_plans_updated_at
  BEFORE UPDATE ON public.career_action_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_enquiries_status ON public.enquiries(status);
CREATE INDEX IF NOT EXISTS idx_enquiries_email ON public.enquiries(email);
CREATE INDEX IF NOT EXISTS idx_enquiries_enquiry_id ON public.enquiries(enquiry_id);
CREATE INDEX IF NOT EXISTS idx_enquiry_followups_enquiry ON public.enquiry_followups(enquiry_id);
CREATE INDEX IF NOT EXISTS idx_career_appointments_student ON public.career_appointments(student_id);
CREATE INDEX IF NOT EXISTS idx_career_action_plans_student ON public.career_action_plans(student_id);

-- Enable RLS
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enquiry_followups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.career_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.career_action_plans ENABLE ROW LEVEL SECURITY;

-- Enquiries Policies (Restricted to Administrators & Public Website Submissions)
CREATE POLICY "Admins manage all enquiries"
  ON public.enquiries
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Allow public web enquiry submissions"
  ON public.enquiries
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Admins manage enquiry followups"
  ON public.enquiry_followups
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

-- Career Guidance Policies
CREATE POLICY "Admins manage all career appointments"
  ON public.career_appointments
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Students view their own career appointments"
  ON public.career_appointments
  FOR SELECT
  TO authenticated
  USING (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

CREATE POLICY "Admins manage all career action plans"
  ON public.career_action_plans
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Students view their own action plan"
  ON public.career_action_plans
  FOR SELECT
  TO authenticated
  USING (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

