-- Migration: 20261121000001_secure_student_deletion_and_recovery.sql
-- Description: Phase 1B.2A — Secure Student Permanent Deletion Backend Corrections.
--
-- Core Safeguards Implemented:
-- 1. Hardened Foreign Key Constraints (ON DELETE RESTRICT):
--    - public.course_enrollments: Changes FK from CASCADE to RESTRICT.
--    - public.assessment_results: Changes FK from CASCADE to RESTRICT.
--    - public.student_subscriptions: Changes FK from CASCADE to RESTRICT.
--    - public.career_appointments: Changes FK from CASCADE to RESTRICT.
--    - public.career_action_plans: Changes FK from CASCADE to RESTRICT.
--    (public.payments is already ON DELETE RESTRICT from migration 20261120000001).
--    Physical database constraints now guarantee that no student with existing academic,
--    financial, subscription, or advisory records can EVER be deleted, even in race conditions.
--
-- 2. Durable Deletion Recovery Tracking:
--    - public.student_deletion_records: Persists student identity (UUID, code, email, profile_id)
--      before and during irreversible operations.
--    - Enables safe, idempotent recovery if Supabase Auth Admin API deletion fails or times out.
--
-- 3. Atomic Safe Student Deletion RPC (public.safe_delete_student):
--    - Restricted strictly to verified Super Admins.
--    - Acquires transaction-level advisory lock (pg_advisory_xact_lock) on student UUID hash.
--    - Locks student row FOR UPDATE.
--    - Re-evaluates all 9 critical protected dependency classes inside the atomic transaction.
--    - Safely disposes of non-ledger junction records (student_categories) and personal notifications.
--    - Records durable pre-deletion recovery entry.
--    - Executes deletion of public.students row.
--
-- 4. Idempotent Recovery Helpers:
--    - public.get_student_deletion_recovery_record(p_student_id UUID)
--    - public.update_student_deletion_status(p_record_id UUID, p_status TEXT, p_error_message TEXT)
--
-- 5. Updated Student Deletion Eligibility RPC (public.check_student_deletion_eligibility):
--    - Differentiates protected ledger dependencies (which block deletion) from disposable
--      stream assignments and notifications (which are automatically cleaned up during deletion).

-- ============================================================================
-- 1. Hardened Foreign Key Constraints (Physical Relational Safeguards)
-- ============================================================================

-- A. Harden public.course_enrollments (ON DELETE RESTRICT)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'course_enrollments_student_id_fkey'
      AND conrelid = 'public.course_enrollments'::regclass
  ) THEN
    ALTER TABLE public.course_enrollments
      DROP CONSTRAINT course_enrollments_student_id_fkey;
  END IF;

  ALTER TABLE public.course_enrollments
    ADD CONSTRAINT course_enrollments_student_id_fkey
    FOREIGN KEY (student_id)
    REFERENCES public.students(id)
    ON DELETE RESTRICT;
END $$;

COMMENT ON CONSTRAINT course_enrollments_student_id_fkey ON public.course_enrollments IS
  'Guarantees academic history preservation by restricting student deletion if enrollment records exist.';

-- B. Harden public.assessment_results (ON DELETE RESTRICT)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'assessment_results_student_id_fkey'
      AND conrelid = 'public.assessment_results'::regclass
  ) THEN
    ALTER TABLE public.assessment_results
      DROP CONSTRAINT assessment_results_student_id_fkey;
  END IF;

  ALTER TABLE public.assessment_results
    ADD CONSTRAINT assessment_results_student_id_fkey
    FOREIGN KEY (student_id)
    REFERENCES public.students(id)
    ON DELETE RESTRICT;
END $$;

COMMENT ON CONSTRAINT assessment_results_student_id_fkey ON public.assessment_results IS
  'Guarantees examination and grading integrity by restricting student deletion if assessment results exist.';

-- C. Harden public.student_subscriptions (ON DELETE RESTRICT)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'student_subscriptions_student_id_fkey'
      AND conrelid = 'public.student_subscriptions'::regclass
  ) THEN
    ALTER TABLE public.student_subscriptions
      DROP CONSTRAINT student_subscriptions_student_id_fkey;
  END IF;

  ALTER TABLE public.student_subscriptions
    ADD CONSTRAINT student_subscriptions_student_id_fkey
    FOREIGN KEY (student_id)
    REFERENCES public.students(id)
    ON DELETE RESTRICT;
END $$;

COMMENT ON CONSTRAINT student_subscriptions_student_id_fkey ON public.student_subscriptions IS
  'Guarantees subscription history preservation by restricting student deletion if subscription records exist.';

-- D. Harden public.career_appointments (ON DELETE RESTRICT)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'career_appointments_student_id_fkey'
      AND conrelid = 'public.career_appointments'::regclass
  ) THEN
    ALTER TABLE public.career_appointments
      DROP CONSTRAINT career_appointments_student_id_fkey;
  END IF;

  ALTER TABLE public.career_appointments
    ADD CONSTRAINT career_appointments_student_id_fkey
    FOREIGN KEY (student_id)
    REFERENCES public.students(id)
    ON DELETE RESTRICT;
END $$;

COMMENT ON CONSTRAINT career_appointments_student_id_fkey ON public.career_appointments IS
  'Guarantees career counseling appointment history by restricting student deletion if appointments exist.';

-- E. Harden public.career_action_plans (ON DELETE RESTRICT)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'career_action_plans_student_id_fkey'
      AND conrelid = 'public.career_action_plans'::regclass
  ) THEN
    ALTER TABLE public.career_action_plans
      DROP CONSTRAINT career_action_plans_student_id_fkey;
  END IF;

  ALTER TABLE public.career_action_plans
    ADD CONSTRAINT career_action_plans_student_id_fkey
    FOREIGN KEY (student_id)
    REFERENCES public.students(id)
    ON DELETE RESTRICT;
END $$;

COMMENT ON CONSTRAINT career_action_plans_student_id_fkey ON public.career_action_plans IS
  'Guarantees career action plan preservation by restricting student deletion if action plans exist.';

-- ============================================================================
-- 2. Disposable Junction Table Verification (public.student_categories)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.student_categories (
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.course_categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (student_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_student_categories_student_id ON public.student_categories(student_id);
CREATE INDEX IF NOT EXISTS idx_student_categories_category_id ON public.student_categories(category_id);

ALTER TABLE public.student_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage student categories" ON public.student_categories;
CREATE POLICY "Admins manage student categories"
  ON public.student_categories
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

DROP POLICY IF EXISTS "Students view their own categories" ON public.student_categories;
CREATE POLICY "Students view their own categories"
  ON public.student_categories
  FOR SELECT
  TO authenticated
  USING (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

-- ============================================================================
-- 3. Durable Deletion Recovery Records Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.student_deletion_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL,
  student_code TEXT NOT NULL,
  profile_id UUID,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'db_deleted' CHECK (status IN ('pending', 'db_deleted', 'completed', 'failed_auth')),
  error_message TEXT,
  retry_count INT NOT NULL DEFAULT 0,
  requested_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_student_deletion_records_student_id ON public.student_deletion_records(student_id);
CREATE INDEX IF NOT EXISTS idx_student_deletion_records_profile_id ON public.student_deletion_records(profile_id);
CREATE INDEX IF NOT EXISTS idx_student_deletion_records_status ON public.student_deletion_records(status);
CREATE INDEX IF NOT EXISTS idx_student_deletion_records_email ON public.student_deletion_records(email);

ALTER TABLE public.student_deletion_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super Admins view deletion records" ON public.student_deletion_records;
CREATE POLICY "Super Admins view deletion records"
  ON public.student_deletion_records
  FOR SELECT
  TO authenticated
  USING (public.is_super_admin());

DROP POLICY IF EXISTS "Super Admins manage deletion records" ON public.student_deletion_records;
CREATE POLICY "Super Admins manage deletion records"
  ON public.student_deletion_records
  FOR ALL
  TO authenticated
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

REVOKE ALL ON TABLE public.student_deletion_records FROM anon, public;
GRANT SELECT, INSERT, UPDATE ON TABLE public.student_deletion_records TO authenticated;
GRANT ALL ON TABLE public.student_deletion_records TO service_role;

-- ============================================================================
-- 4. Atomic Safe Student Deletion RPC (public.safe_delete_student)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.safe_delete_student(p_student_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_student RECORD;
  v_payments_count INT := 0;
  v_enrollments_count INT := 0;
  v_assessments_count INT := 0;
  v_subscriptions_count INT := 0;
  v_career_appointments_count INT := 0;
  v_career_action_plans_count INT := 0;
  v_lesson_progress_count INT := 0;
  v_live_class_attendees_count INT := 0;
  v_assignment_submissions_count INT := 0;
  v_categories_count INT := 0;
  v_notifications_count INT := 0;
  v_deletion_record_id UUID;
  v_admin_id UUID;
BEGIN
  -- 1. Authorization: Only verified Super Admins can execute
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Access denied. Super Admin authority is strictly required to permanently delete student records.';
  END IF;

  v_admin_id := auth.uid();

  -- 2. Concurrency Protection:
  -- A. Acquire transaction-level advisory lock on student UUID hash
  PERFORM pg_advisory_xact_lock(hashtext('safe_delete_student_' || p_student_id::text));

  -- B. Lock the target student row FOR UPDATE
  SELECT * INTO v_student
  FROM public.students
  WHERE id = p_student_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'STUDENT_NOT_FOUND',
      'message', 'Student record does not exist or has already been removed.'
    );
  END IF;

  -- Prevent Super Admin from deleting their own linked account
  IF v_student.profile_id IS NOT NULL AND v_student.profile_id = v_admin_id THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'SELF_DELETION_PROHIBITED',
      'message', 'Super Administrators cannot delete their own account.'
    );
  END IF;

  -- 3. Re-verify ALL protected dependencies within the locked transaction
  SELECT COUNT(*) INTO v_payments_count FROM public.payments WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_enrollments_count FROM public.course_enrollments WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_assessments_count FROM public.assessment_results WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_subscriptions_count FROM public.student_subscriptions WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_career_appointments_count FROM public.career_appointments WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_career_action_plans_count FROM public.career_action_plans WHERE student_id = p_student_id;

  IF to_regclass('public.lesson_progress') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.lesson_progress WHERE student_id = $1'
      INTO v_lesson_progress_count USING p_student_id;
  END IF;

  IF to_regclass('public.live_class_attendees') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.live_class_attendees WHERE student_id = $1'
      INTO v_live_class_attendees_count USING p_student_id;
  END IF;

  IF to_regclass('public.assignment_submissions') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.assignment_submissions WHERE student_id = $1'
      INTO v_assignment_submissions_count USING p_student_id;
  END IF;

  -- If ANY protected academic or financial dependency exists, REJECT deletion immediately
  IF v_payments_count > 0
     OR v_enrollments_count > 0
     OR v_assessments_count > 0
     OR v_subscriptions_count > 0
     OR v_career_appointments_count > 0
     OR v_career_action_plans_count > 0
     OR v_lesson_progress_count > 0
     OR v_live_class_attendees_count > 0
     OR v_assignment_submissions_count > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'PROTECTED_DEPENDENCIES_EXIST',
      'message', format('Student "%s" (%s) cannot be deleted because protected academic or financial records exist. Deactivate or suspend the account instead.', v_student.full_name, v_student.student_id),
      'counts', jsonb_build_object(
        'payments', v_payments_count,
        'course_enrollments', v_enrollments_count,
        'assessment_results', v_assessments_count,
        'student_subscriptions', v_subscriptions_count,
        'career_appointments', v_career_appointments_count,
        'career_action_plans', v_career_action_plans_count,
        'lesson_progress', v_lesson_progress_count,
        'live_class_attendees', v_live_class_attendees_count,
        'assignment_submissions', v_assignment_submissions_count
      )
    );
  END IF;

  -- 4. Create durable pre-deletion recovery record in public.student_deletion_records
  INSERT INTO public.student_deletion_records (
    student_id,
    student_code,
    profile_id,
    email,
    full_name,
    status,
    requested_by,
    created_at,
    updated_at
  )
  VALUES (
    p_student_id,
    v_student.student_id,
    v_student.profile_id,
    LOWER(v_student.email),
    v_student.full_name,
    'db_deleted',
    v_admin_id,
    NOW(),
    NOW()
  )
  RETURNING id INTO v_deletion_record_id;

  -- 5. Clean up genuinely disposable junction and transient personal records
  IF to_regclass('public.student_categories') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.student_categories WHERE student_id = $1'
      USING p_student_id;
    GET DIAGNOSTICS v_categories_count = ROW_COUNT;
  END IF;

  IF v_student.profile_id IS NOT NULL THEN
    DELETE FROM public.notifications WHERE user_id = v_student.profile_id;
    GET DIAGNOSTICS v_notifications_count = ROW_COUNT;
  END IF;

  -- 6. Perform physical deletion of public.students row
  -- Protected by physical ON DELETE RESTRICT on payments, enrollments, assessments, etc.
  DELETE FROM public.students WHERE id = p_student_id;

  -- 7. Return structured operational payload
  RETURN jsonb_build_object(
    'success', TRUE,
    'deletion_record_id', v_deletion_record_id,
    'student_id', p_student_id,
    'student_code', v_student.student_id,
    'profile_id', v_student.profile_id,
    'email', LOWER(v_student.email),
    'full_name', v_student.full_name,
    'disposable_cleaned', jsonb_build_object(
      'student_categories', v_categories_count,
      'personal_notifications', v_notifications_count
    ),
    'message', format('Student "%s" (%s) database records have been permanently deleted.', v_student.full_name, v_student.student_id)
  );
END;
$$;

COMMENT ON FUNCTION public.safe_delete_student(UUID) IS
  'Performs an atomic, dependency-guarded deletion of a student and creates a durable Auth deletion recovery record.';

REVOKE ALL ON FUNCTION public.safe_delete_student(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.safe_delete_student(UUID) TO authenticated;

-- ============================================================================
-- 5. Recovery Helper RPCs
-- ============================================================================

-- A. Fetch recovery record for idempotent retries
CREATE OR REPLACE FUNCTION public.get_student_deletion_recovery_record(p_student_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_record RECORD;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Access denied. Super Admin authority is strictly required.';
  END IF;

  SELECT * INTO v_record
  FROM public.student_deletion_records
  WHERE student_id = p_student_id
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('exists', FALSE);
  END IF;

  RETURN jsonb_build_object(
    'exists', TRUE,
    'id', v_record.id,
    'student_id', v_record.student_id,
    'student_code', v_record.student_code,
    'profile_id', v_record.profile_id,
    'email', v_record.email,
    'full_name', v_record.full_name,
    'status', v_record.status,
    'error_message', v_record.error_message,
    'retry_count', v_record.retry_count,
    'created_at', v_record.created_at,
    'completed_at', v_record.completed_at
  );
END;
$$;

COMMENT ON FUNCTION public.get_student_deletion_recovery_record(UUID) IS
  'Retrieves the durable deletion recovery record for a student to support idempotent retry of Auth deletion.';

REVOKE ALL ON FUNCTION public.get_student_deletion_recovery_record(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_deletion_recovery_record(UUID) TO authenticated;

-- B. Update deletion recovery record status
CREATE OR REPLACE FUNCTION public.update_student_deletion_status(
  p_record_id UUID,
  p_status TEXT,
  p_error_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Access denied. Super Admin authority is strictly required.';
  END IF;

  UPDATE public.student_deletion_records
  SET
    status = p_status,
    error_message = p_error_message,
    completed_at = CASE WHEN p_status = 'completed' THEN NOW() ELSE completed_at END,
    updated_at = NOW(),
    retry_count = retry_count + 1
  WHERE id = p_record_id;

  RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION public.update_student_deletion_status(UUID, TEXT, TEXT) IS
  'Updates the status of a durable student deletion recovery record.';

REVOKE ALL ON FUNCTION public.update_student_deletion_status(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_student_deletion_status(UUID, TEXT, TEXT) TO authenticated;

-- ============================================================================
-- 6. Updated Student Deletion Eligibility RPC
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_student_deletion_eligibility(p_student_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_student RECORD;
  v_payments_count INTEGER := 0;
  v_enrollments_count INTEGER := 0;
  v_assessment_results_count INTEGER := 0;
  v_subscriptions_count INTEGER := 0;
  v_career_appointments_count INTEGER := 0;
  v_career_action_plans_count INTEGER := 0;
  v_notifications_count INTEGER := 0;
  v_student_categories_count INTEGER := 0;
  v_lesson_progress_count INTEGER := 0;
  v_live_class_attendees_count INTEGER := 0;
  v_assignment_submissions_count INTEGER := 0;
  v_activity_logs_count INTEGER := 0;
  v_is_eligible BOOLEAN := FALSE;
  v_reasons JSONB := '[]'::JSONB;
BEGIN
  -- 1. Server-Side Authorization Check
  IF NOT public.is_admin_or_super() THEN
    RAISE EXCEPTION 'Access denied. Only authorized administrators can check student deletion eligibility.';
  END IF;

  -- 2. Validate student existence
  SELECT * INTO v_student
  FROM public.students
  WHERE id = p_student_id;

  IF NOT FOUND THEN
    -- Check if a deletion recovery record exists for this student ID
    IF EXISTS (SELECT 1 FROM public.student_deletion_records WHERE student_id = p_student_id) THEN
      RETURN jsonb_build_object(
        'exists', FALSE,
        'is_eligible', FALSE,
        'student_id', p_student_id,
        'has_recovery_record', TRUE,
        'reasons', jsonb_build_array('Student database row has already been deleted. A durable recovery record exists for Auth cleanup.'),
        'counts', jsonb_build_object()
      );
    END IF;

    RETURN jsonb_build_object(
      'exists', FALSE,
      'is_eligible', FALSE,
      'student_id', p_student_id,
      'has_recovery_record', FALSE,
      'reasons', jsonb_build_array('Student record does not exist.'),
      'counts', jsonb_build_object()
    );
  END IF;

  -- 3. Query all protected relationship tables
  SELECT COUNT(*) INTO v_payments_count FROM public.payments WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_enrollments_count FROM public.course_enrollments WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_assessment_results_count FROM public.assessment_results WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_subscriptions_count FROM public.student_subscriptions WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_career_appointments_count FROM public.career_appointments WHERE student_id = p_student_id;
  SELECT COUNT(*) INTO v_career_action_plans_count FROM public.career_action_plans WHERE student_id = p_student_id;

  -- 4. Check personal notifications linked to the student profile
  IF v_student.profile_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_notifications_count
    FROM public.notifications
    WHERE user_id = v_student.profile_id;
  END IF;

  -- 5. Query optional tables
  IF to_regclass('public.student_categories') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.student_categories WHERE student_id = $1'
      INTO v_student_categories_count USING p_student_id;
  END IF;

  IF to_regclass('public.lesson_progress') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.lesson_progress WHERE student_id = $1'
      INTO v_lesson_progress_count USING p_student_id;
  END IF;

  IF to_regclass('public.live_class_attendees') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.live_class_attendees WHERE student_id = $1'
      INTO v_live_class_attendees_count USING p_student_id;
  END IF;

  IF to_regclass('public.assignment_submissions') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.assignment_submissions WHERE student_id = $1'
      INTO v_assignment_submissions_count USING p_student_id;
  END IF;

  IF to_regclass('public.activity_logs') IS NOT NULL AND v_student.profile_id IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.activity_logs WHERE admin_id = $1'
      INTO v_activity_logs_count USING v_student.profile_id;
  END IF;

  -- 6. Evaluate blocking dependencies
  IF v_payments_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s recorded financial payment transaction(s). Institutional compliance requires keeping financial ledgers.', v_payments_count)
    );
  END IF;

  IF v_enrollments_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s course enrollment record(s). Deletion would erase academic enrollment tracking.', v_enrollments_count)
    );
  END IF;

  IF v_assessment_results_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s completed assessment examination result(s). Deletion would erase graded evaluations.', v_assessment_results_count)
    );
  END IF;

  IF v_subscriptions_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s active or historical subscription record(s).', v_subscriptions_count)
    );
  END IF;

  IF v_career_appointments_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s career counseling appointment(s).', v_career_appointments_count)
    );
  END IF;

  IF v_career_action_plans_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      'Student has a career action plan on record.'
    );
  END IF;

  IF v_lesson_progress_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s lesson progress record(s).', v_lesson_progress_count)
    );
  END IF;

  IF v_live_class_attendees_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has attended or registered for %s live class webinar(s).', v_live_class_attendees_count)
    );
  END IF;

  IF v_assignment_submissions_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has submitted %s assignment coursework item(s).', v_assignment_submissions_count)
    );
  END IF;

  -- Eligibility is TRUE ONLY IF all critical academic, financial, advisory, and progress records are ZERO
  -- Note: student_categories and personal in-app notifications are disposable stream assignments
  -- that safe_delete_student automatically disposes of during deletion.
  IF v_payments_count = 0
     AND v_enrollments_count = 0
     AND v_assessment_results_count = 0
     AND v_subscriptions_count = 0
     AND v_career_appointments_count = 0
     AND v_career_action_plans_count = 0
     AND v_lesson_progress_count = 0
     AND v_live_class_attendees_count = 0
     AND v_assignment_submissions_count = 0 THEN
    v_is_eligible := TRUE;
    v_reasons := jsonb_build_array(
      'Student has zero dependent financial, academic, advisory, or progress records. Account is eligible for safe permanent deletion via the Super Admin Edge Function.'
    );
    IF v_student_categories_count > 0 OR v_notifications_count > 0 THEN
      v_reasons := v_reasons || jsonb_build_array(
        format('Disposable records (%s category stream assignment(s), %s personal in-app notification(s)) will be automatically cleaned up during deletion.', v_student_categories_count, v_notifications_count)
      );
    END IF;
  END IF;

  -- 7. Return structured audit payload
  RETURN jsonb_build_object(
    'exists', TRUE,
    'student_id', p_student_id,
    'student_code', v_student.student_id,
    'full_name', v_student.full_name,
    'email', v_student.email,
    'account_status', v_student.account_status,
    'profile_id', v_student.profile_id,
    'is_eligible', v_is_eligible,
    'reasons', v_reasons,
    'counts', jsonb_build_object(
      'payments', v_payments_count,
      'course_enrollments', v_enrollments_count,
      'assessment_results', v_assessment_results_count,
      'student_subscriptions', v_subscriptions_count,
      'career_appointments', v_career_appointments_count,
      'career_action_plans', v_career_action_plans_count,
      'notifications', v_notifications_count,
      'student_categories', v_student_categories_count,
      'lesson_progress', v_lesson_progress_count,
      'live_class_attendees', v_live_class_attendees_count,
      'assignment_submissions', v_assignment_submissions_count,
      'activity_logs', v_activity_logs_count
    ),
    'blocking_dependencies', jsonb_build_object(
      'has_payments', (v_payments_count > 0),
      'has_enrollments', (v_enrollments_count > 0),
      'has_assessments', (v_assessment_results_count > 0),
      'has_subscriptions', (v_subscriptions_count > 0),
      'has_career_records', (v_career_appointments_count > 0 OR v_career_action_plans_count > 0),
      'has_progress', (v_lesson_progress_count > 0),
      'has_live_attendance', (v_live_class_attendees_count > 0),
      'has_assignment_submissions', (v_assignment_submissions_count > 0)
    ),
    'recommendation', CASE
      WHEN v_is_eligible THEN 'PERMIT_HARD_DELETE_VIA_EDGE_FUNCTION'
      ELSE 'DEACTIVATE_OR_SUSPEND'
    END
  );
END;
$$;

COMMENT ON FUNCTION public.check_student_deletion_eligibility(UUID) IS
  'Performs an administrative audit of all dependencies linked to a student and determines deletion safety.';

REVOKE ALL ON FUNCTION public.check_student_deletion_eligibility(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_student_deletion_eligibility(UUID) TO authenticated;
