-- Migration: 20261028000007_create_resources_notifications_classes.sql
-- Description: Learning materials repository, in-app notifications, and live class schedules

-- Resource & Notification Enums
DO $$ BEGIN
  CREATE TYPE resource_type AS ENUM ('pdf', 'document', 'video', 'link', 'image');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE resource_category AS ENUM ('study_material', 'career', 'exam_prep', 'course', 'government_exam');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE resource_visibility AS ENUM ('public', 'enrolled', 'private');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM ('student', 'instructor', 'course', 'payment', 'class', 'system');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_priority AS ENUM ('low', 'medium', 'high');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE live_class_status AS ENUM ('upcoming', 'live', 'completed', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Resources Table
CREATE TABLE IF NOT EXISTS public.resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type resource_type NOT NULL,
  category resource_category NOT NULL,
  file_size TEXT,
  download_url TEXT,
  visibility resource_visibility NOT NULL DEFAULT 'enrolled',
  uploaded_by TEXT NOT NULL,
  download_count INTEGER NOT NULL DEFAULT 0 CHECK (download_count >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_resources_updated_at ON public.resources;
CREATE TRIGGER trg_resources_updated_at
  BEFORE UPDATE ON public.resources
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL indicates system-wide broadcast
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type notification_type NOT NULL DEFAULT 'system',
  priority notification_priority NOT NULL DEFAULT 'low',
  read BOOLEAN NOT NULL DEFAULT FALSE,
  action_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Live Classes Table
CREATE TABLE IF NOT EXISTS public.live_classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  course_id UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  course_name TEXT NOT NULL,
  instructor_id UUID NOT NULL REFERENCES public.instructors(id) ON DELETE CASCADE,
  instructor_name TEXT NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 60 CHECK (duration_minutes > 0),
  status live_class_status NOT NULL DEFAULT 'upcoming',
  meeting_link TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_resources_visibility ON public.resources(visibility);
CREATE INDEX IF NOT EXISTS idx_resources_category ON public.resources(category);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);
CREATE INDEX IF NOT EXISTS idx_live_classes_course ON public.live_classes(course_id);
CREATE INDEX IF NOT EXISTS idx_live_classes_instructor ON public.live_classes(instructor_id);
CREATE INDEX IF NOT EXISTS idx_live_classes_scheduled_at ON public.live_classes(scheduled_at);

-- Enable RLS
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_classes ENABLE ROW LEVEL SECURITY;

-- Resources Policies
CREATE POLICY "Public resources readable by all"
  ON public.resources
  FOR SELECT
  USING (visibility = 'public');

CREATE POLICY "Enrolled resources viewable by authenticated users"
  ON public.resources
  FOR SELECT
  TO authenticated
  USING (visibility = 'enrolled' OR public.is_admin_or_super() OR public.get_auth_role() = 'instructor');

CREATE POLICY "Private resources viewable only by staff"
  ON public.resources
  FOR SELECT
  TO authenticated
  USING (public.is_admin_or_super() OR public.get_auth_role() = 'instructor');

CREATE POLICY "Admins and instructors manage resources"
  ON public.resources
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super() OR public.get_auth_role() = 'instructor')
  WITH CHECK (public.is_admin_or_super() OR public.get_auth_role() = 'instructor');

-- Notifications Policies
CREATE POLICY "Users read their personal or system-wide notifications"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR user_id IS NULL OR public.is_admin_or_super());

CREATE POLICY "Users mark their own notifications as read"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid() OR (user_id IS NULL AND public.is_admin_or_super()))
  WITH CHECK (user_id = auth.uid() OR (user_id IS NULL AND public.is_admin_or_super()));

CREATE POLICY "Admins manage all notifications"
  ON public.notifications
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

-- Live Classes Policies
CREATE POLICY "Admins manage all live classes"
  ON public.live_classes
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Instructors manage their assigned live classes"
  ON public.live_classes
  FOR ALL
  TO authenticated
  USING (instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid()))
  WITH CHECK (instructor_id IN (SELECT id FROM public.instructors WHERE profile_id = auth.uid()));

CREATE POLICY "Enrolled students view live classes for their courses"
  ON public.live_classes
  FOR SELECT
  TO authenticated
  USING (
    course_id IN (
      SELECT ce.course_id FROM public.course_enrollments ce
      JOIN public.students s ON s.id = ce.student_id
      WHERE s.profile_id = auth.uid()
    )
  );

