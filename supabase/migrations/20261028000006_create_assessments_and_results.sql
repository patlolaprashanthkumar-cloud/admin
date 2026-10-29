-- Migration: 20261028000006_create_assessments_and_results.sql
-- Description: Assessments, questions bank, assignments, and student assessment results

-- Assessment Enums
DO $$ BEGIN
  CREATE TYPE assessment_type AS ENUM ('mcq', 'assignment', 'project', 'quiz');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE assessment_status AS ENUM ('draft', 'scheduled', 'active', 'completed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE question_type AS ENUM ('mcq', 'true_false', 'short_answer');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Assessment Categories Table
CREATE TABLE IF NOT EXISTS public.assessment_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Questions Table
CREATE TABLE IF NOT EXISTS public.questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES public.assessment_categories(id) ON DELETE SET NULL,
  question_text TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '[]',
  marks INTEGER NOT NULL DEFAULT 1 CHECK (marks > 0),
  type question_type NOT NULL DEFAULT 'mcq',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Assessments Table
CREATE TABLE IF NOT EXISTS public.assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category_id UUID REFERENCES public.assessment_categories(id) ON DELETE SET NULL,
  type assessment_type NOT NULL DEFAULT 'mcq',
  total_marks INTEGER NOT NULL DEFAULT 100 CHECK (total_marks > 0),
  passing_marks INTEGER NOT NULL DEFAULT 40 CHECK (passing_marks >= 0 AND passing_marks <= total_marks),
  duration_minutes INTEGER NOT NULL DEFAULT 60 CHECK (duration_minutes >= 0),
  status assessment_status NOT NULL DEFAULT 'draft',
  scheduled_at TIMESTAMPTZ,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_assessments_updated_at ON public.assessments;
CREATE TRIGGER trg_assessments_updated_at
  BEFORE UPDATE ON public.assessments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Assessment Questions Join Table
CREATE TABLE IF NOT EXISTS public.assessment_questions (
  assessment_id UUID NOT NULL REFERENCES public.assessments(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (assessment_id, question_id)
);

-- Assessment Course Assignments Join Table
CREATE TABLE IF NOT EXISTS public.assessment_course_assignments (
  assessment_id UUID NOT NULL REFERENCES public.assessments(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  PRIMARY KEY (assessment_id, course_id)
);

-- Assessment Results Table
CREATE TABLE IF NOT EXISTS public.assessment_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id UUID NOT NULL REFERENCES public.assessments(id) ON DELETE CASCADE,
  assessment_title TEXT NOT NULL,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  score NUMERIC(6,2) NOT NULL CHECK (score >= 0),
  total_marks NUMERIC(6,2) NOT NULL CHECK (total_marks > 0),
  percentage NUMERIC(5,2) NOT NULL CHECK (percentage >= 0 AND percentage <= 100),
  passed BOOLEAN NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  answers JSONB DEFAULT '[]'
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_assessments_status ON public.assessments(status);
CREATE INDEX IF NOT EXISTS idx_assessments_category ON public.assessments(category_id);
CREATE INDEX IF NOT EXISTS idx_assessment_results_student ON public.assessment_results(student_id);
CREATE INDEX IF NOT EXISTS idx_assessment_results_assessment ON public.assessment_results(assessment_id);

-- Enable RLS
ALTER TABLE public.assessment_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_course_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_results ENABLE ROW LEVEL SECURITY;

-- Categories & Questions: Staff & Admins manage
CREATE POLICY "Public read assessment categories" ON public.assessment_categories FOR SELECT USING (true);
CREATE POLICY "Admins manage assessment categories" ON public.assessment_categories FOR ALL TO authenticated USING (public.is_admin_or_super()) WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Staff read questions" ON public.questions FOR SELECT TO authenticated USING (public.is_admin_or_super() OR public.get_auth_role() = 'instructor');
CREATE POLICY "Admins manage questions" ON public.questions FOR ALL TO authenticated USING (public.is_admin_or_super()) WITH CHECK (public.is_admin_or_super());

-- Assessments Policies
CREATE POLICY "Admins and instructors view all assessments"
  ON public.assessments
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin_or_super()
    OR public.get_auth_role() = 'instructor'
    OR (
      status IN ('active', 'completed', 'scheduled')
      AND id IN (
        SELECT aca.assessment_id FROM public.assessment_course_assignments aca
        JOIN public.course_enrollments ce ON ce.course_id = aca.course_id
        JOIN public.students s ON s.id = ce.student_id
        WHERE s.profile_id = auth.uid()
      )
    )
  );

CREATE POLICY "Admins manage assessments"
  ON public.assessments
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Staff manage assessment assignments"
  ON public.assessment_questions
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super() OR public.get_auth_role() = 'instructor')
  WITH CHECK (public.is_admin_or_super() OR public.get_auth_role() = 'instructor');

CREATE POLICY "Staff manage course assessment assignments"
  ON public.assessment_course_assignments
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super() OR public.get_auth_role() = 'instructor')
  WITH CHECK (public.is_admin_or_super() OR public.get_auth_role() = 'instructor');

-- Assessment Results Policies
CREATE POLICY "Admins and instructors view assessment results"
  ON public.assessment_results
  FOR SELECT
  TO authenticated
  USING (public.is_admin_or_super() OR public.get_auth_role() = 'instructor');

CREATE POLICY "Students view their own assessment results"
  ON public.assessment_results
  FOR SELECT
  TO authenticated
  USING (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

CREATE POLICY "Students submit assessment attempts"
  ON public.assessment_results
  FOR INSERT
  TO authenticated
  WITH CHECK (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

CREATE POLICY "Admins manage assessment results"
  ON public.assessment_results
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

