-- Migration: 20261028000003_create_courses_and_enrollments.sql
-- Description: Course catalog, modules, lessons, and enrollment tracking with strict uniqueness

-- Course Enums
DO $$ BEGIN
  CREATE TYPE course_status AS ENUM ('draft', 'published', 'archived');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE learning_format AS ENUM ('live', 'recorded', 'hybrid');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE lesson_type AS ENUM ('video', 'reading', 'quiz', 'assignment');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Course Categories Table
CREATE TABLE IF NOT EXISTS public.course_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#335598',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Courses Table
CREATE TABLE IF NOT EXISTS public.courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category_id UUID REFERENCES public.course_categories(id) ON DELETE SET NULL,
  category_name TEXT NOT NULL,
  thumbnail_url TEXT,
  instructor_id UUID REFERENCES public.instructors(id) ON DELETE SET NULL,
  duration_weeks INTEGER NOT NULL DEFAULT 8 CHECK (duration_weeks > 0),
  fee NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (fee >= 0),
  learning_objectives TEXT[] NOT NULL DEFAULT '{}',
  prerequisites TEXT[] NOT NULL DEFAULT '{}',
  format learning_format NOT NULL DEFAULT 'hybrid',
  status course_status NOT NULL DEFAULT 'draft',
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_courses_updated_at ON public.courses;
CREATE TRIGGER trg_courses_updated_at
  BEFORE UPDATE ON public.courses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Modules Table
CREATE TABLE IF NOT EXISTS public.course_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lessons Table
CREATE TABLE IF NOT EXISTS public.course_lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID NOT NULL REFERENCES public.course_modules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 0 CHECK (duration_minutes >= 0),
  type lesson_type NOT NULL DEFAULT 'video',
  order_index INTEGER NOT NULL DEFAULT 1,
  content_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Course Enrollments Table (Strictly enforces unique student-course pairs)
CREATE TABLE IF NOT EXISTS public.course_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'dropped')),
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  CONSTRAINT uq_student_course_enrollment UNIQUE (student_id, course_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_courses_status ON public.courses(status);
CREATE INDEX IF NOT EXISTS idx_courses_instructor_id ON public.courses(instructor_id);
CREATE INDEX IF NOT EXISTS idx_courses_category_id ON public.courses(category_id);
CREATE INDEX IF NOT EXISTS idx_course_modules_course ON public.course_modules(course_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_module ON public.course_lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON public.course_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON public.course_enrollments(course_id);

-- Enable RLS
ALTER TABLE public.course_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_enrollments ENABLE ROW LEVEL SECURITY;

-- Categories: Read by all, manage by admins
CREATE POLICY "Public read course categories" ON public.course_categories FOR SELECT USING (true);
CREATE POLICY "Admins manage categories" ON public.course_categories FOR ALL TO authenticated USING (public.is_admin_or_super()) WITH CHECK (public.is_admin_or_super());

-- Courses: Read published by all; draft/archived by admin or assigned instructor
CREATE POLICY "Read published courses"
  ON public.courses
  FOR SELECT
  USING (
    status = 'published'
    OR public.is_admin_or_super()
    OR instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid())
  );

CREATE POLICY "Admins manage all courses"
  ON public.courses
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Instructors edit their own assigned courses"
  ON public.courses
  FOR UPDATE
  TO authenticated
  USING (instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid()))
  WITH CHECK (instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid()));

-- Modules & Lessons: Visible if course is visible; manageable by admins and assigned instructors
CREATE POLICY "Read course modules"
  ON public.course_modules
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.courses c WHERE c.id = course_id AND (c.status = 'published' OR public.is_admin_or_super() OR c.instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid())))
  );

CREATE POLICY "Manage course modules"
  ON public.course_modules
  FOR ALL
  TO authenticated
  USING (
    public.is_admin_or_super()
    OR EXISTS (SELECT 1 FROM public.courses c WHERE c.id = course_id AND c.instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid()))
  );

CREATE POLICY "Read course lessons"
  ON public.course_lessons
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.course_modules m
      JOIN public.courses c ON c.id = m.course_id
      WHERE m.id = module_id
        AND (c.status = 'published' OR public.is_admin_or_super() OR c.instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid()))
    )
  );

CREATE POLICY "Manage course lessons"
  ON public.course_lessons
  FOR ALL
  TO authenticated
  USING (
    public.is_admin_or_super()
    OR EXISTS (
      SELECT 1 FROM public.course_modules m
      JOIN public.courses c ON c.id = m.course_id
      WHERE m.id = module_id AND c.instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid())
    )
  );

-- Enrollments Policies
CREATE POLICY "Admins manage all enrollments"
  ON public.course_enrollments
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Students view their own enrollments"
  ON public.course_enrollments
  FOR SELECT
  TO authenticated
  USING (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

CREATE POLICY "Instructors view enrollments in their courses"
  ON public.course_enrollments
  FOR SELECT
  TO authenticated
  USING (course_id IN (SELECT id FROM public.courses WHERE instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid())));

