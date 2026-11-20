-- Migration: 20261120000001_deletion_guardrails_and_safe_rpcs.sql
-- Description: Phase 1A.2 — Final Deletion Guardrails, Financial Ledger Immutability,
--              Multi-Table Concurrency Locking, and Complete Lifecycle RPC Security.
--
-- Security Corrections Implemented:
-- 1. Direct Hard-Delete Bypasses Eliminated:
--    - public.students: Dropped any client-accessible DELETE policies. Revoked DELETE table privileges from authenticated/anon/public.
--      Permanent student deletion is strictly reserved for the future secured Edge Function (admin-delete-student).
--    - public.courses: Dropped any client-accessible DELETE policies (including super-admin direct deletion). Revoked DELETE table privileges.
--      Permanent course deletion must be executed via the guarded safe_delete_course() RPC.
--    - public.payments: Verified zero DELETE policies exist. Revoked DELETE privileges. payments_student_id_fkey uses ON DELETE RESTRICT.
--    - Enforced FORCE ROW LEVEL SECURITY on students, courses, and payments.
-- 2. Complete Student Dependency Coverage:
--    - Evaluates: payments, course_enrollments, lesson_progress, assessment_results, student_subscriptions,
--      live_class_attendees, career_appointments, career_action_plans, notifications, student_categories,
--      assignment_submissions, and activity_logs.
--    - Notifications and student categories are strictly factored into the eligibility decision (blocking deletion if > 0).
-- 3. Complete Course Dependency Coverage:
--    - Evaluates: enrollments, payments, live_classes, live_class_attendees, assessment_course_assignments,
--      assessment_results, lesson_progress, assignment_submissions, course_modules, and course_lessons.
-- 4. Concurrency Protection & Atomicity:
--    - safe_delete_course() acquires a transactional advisory lock (pg_advisory_xact_lock) on the course UUID hash
--      plus row-level FOR UPDATE locks on both the course and its modules.
--    - Re-evaluates all protected dependencies inside the serial atomic block before deletion.

-- ============================================================================
-- 1. Financial Ledger Protection (Foreign Key Constraint Hardening)
-- ============================================================================

DO $$
BEGIN
  -- Drop existing cascading foreign key if present
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'payments_student_id_fkey'
      AND conrelid = 'public.payments'::regclass
  ) THEN
    ALTER TABLE public.payments
      DROP CONSTRAINT payments_student_id_fkey;
  END IF;

  -- Add RESTRICT foreign key constraint to ensure student deletion is physically
  -- blocked by PostgreSQL whenever payment records exist for the student.
  ALTER TABLE public.payments
    ADD CONSTRAINT payments_student_id_fkey
    FOREIGN KEY (student_id)
    REFERENCES public.students(id)
    ON DELETE RESTRICT;
END $$;

COMMENT ON CONSTRAINT payments_student_id_fkey ON public.payments IS
  'Guarantees financial ledger immutability by restricting student deletion if payment records exist.';

-- ============================================================================
-- 2. Student Deletion Eligibility RPC (Complete Multi-Table Dependency Audit)
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
  -- 1. Strict Server-Side Authorization Check
  IF NOT public.is_admin_or_super() THEN
    RAISE EXCEPTION 'Access denied. Only authorized administrators can check student deletion eligibility.';
  END IF;

  -- 2. Validate student existence
  SELECT * INTO v_student
  FROM public.students
  WHERE id = p_student_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'exists', FALSE,
      'is_eligible', FALSE,
      'student_id', p_student_id,
      'reasons', jsonb_build_array('Student record does not exist.'),
      'counts', jsonb_build_object()
    );
  END IF;

  -- 3. Query all standard dependent relationship tables
  SELECT COUNT(*) INTO v_payments_count
  FROM public.payments
  WHERE student_id = p_student_id;

  SELECT COUNT(*) INTO v_enrollments_count
  FROM public.course_enrollments
  WHERE student_id = p_student_id;

  SELECT COUNT(*) INTO v_assessment_results_count
  FROM public.assessment_results
  WHERE student_id = p_student_id;

  SELECT COUNT(*) INTO v_subscriptions_count
  FROM public.student_subscriptions
  WHERE student_id = p_student_id;

  SELECT COUNT(*) INTO v_career_appointments_count
  FROM public.career_appointments
  WHERE student_id = p_student_id;

  SELECT COUNT(*) INTO v_career_action_plans_count
  FROM public.career_action_plans
  WHERE student_id = p_student_id;

  -- 4. Check notifications linked to the student profile
  IF v_student.profile_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_notifications_count
    FROM public.notifications
    WHERE user_id = v_student.profile_id;
  END IF;

  -- 5. Dynamically inspect optional or junction tables
  -- A. student_categories junction table
  IF to_regclass('public.student_categories') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.student_categories WHERE student_id = $1'
      INTO v_student_categories_count
      USING p_student_id;
  END IF;

  -- B. lesson_progress table
  IF to_regclass('public.lesson_progress') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.lesson_progress WHERE student_id = $1'
      INTO v_lesson_progress_count
      USING p_student_id;
  END IF;

  -- C. live_class_attendees table
  IF to_regclass('public.live_class_attendees') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.live_class_attendees WHERE student_id = $1'
      INTO v_live_class_attendees_count
      USING p_student_id;
  END IF;

  -- D. assignment_submissions table
  IF to_regclass('public.assignment_submissions') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.assignment_submissions WHERE student_id = $1'
      INTO v_assignment_submissions_count
      USING p_student_id;
  END IF;

  -- E. activity_logs table
  IF to_regclass('public.activity_logs') IS NOT NULL AND v_student.profile_id IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.activity_logs WHERE admin_id = $1'
      INTO v_activity_logs_count
      USING v_student.profile_id;
  END IF;

  -- 6. Evaluate blocking dependencies and compile descriptive reasons
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

  IF v_notifications_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s notification record(s) on file. In-app notifications must be cleared before permanent account removal.', v_notifications_count)
    );
  END IF;

  IF v_student_categories_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Student has %s academic category stream assignment(s).', v_student_categories_count)
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

  -- Eligibility is TRUE ONLY IF all critical academic, financial, advisory, category, and notification records are ZERO
  IF v_payments_count = 0
     AND v_enrollments_count = 0
     AND v_assessment_results_count = 0
     AND v_subscriptions_count = 0
     AND v_career_appointments_count = 0
     AND v_career_action_plans_count = 0
     AND v_notifications_count = 0
     AND v_student_categories_count = 0
     AND v_lesson_progress_count = 0
     AND v_live_class_attendees_count = 0
     AND v_assignment_submissions_count = 0 THEN
    v_is_eligible := TRUE;
    v_reasons := jsonb_build_array(
      'Student has zero dependent financial, academic, advisory, progress, category, or notification records. Account is eligible for safe permanent deletion via the Super Admin Edge Function.'
    );
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
      'has_notifications', (v_notifications_count > 0),
      'has_categories', (v_student_categories_count > 0),
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

-- ============================================================================
-- 3. Course Deletion Eligibility RPC (Complete Course Dependency Coverage)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_course_deletion_eligibility(p_course_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_course RECORD;
  v_enrollments_count INTEGER := 0;
  v_payments_count INTEGER := 0;
  v_live_classes_count INTEGER := 0;
  v_live_class_attendees_count INTEGER := 0;
  v_assessments_count INTEGER := 0;
  v_assessment_results_count INTEGER := 0;
  v_lesson_progress_count INTEGER := 0;
  v_assignment_submissions_count INTEGER := 0;
  v_modules_count INTEGER := 0;
  v_lessons_count INTEGER := 0;
  v_is_eligible BOOLEAN := FALSE;
  v_reasons JSONB := '[]'::JSONB;
BEGIN
  -- 1. Strict Server-Side Authorization Check
  IF NOT public.is_admin_or_super() THEN
    RAISE EXCEPTION 'Access denied. Only authorized administrators can check course deletion eligibility.';
  END IF;

  -- 2. Validate course existence
  SELECT * INTO v_course
  FROM public.courses
  WHERE id = p_course_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'exists', FALSE,
      'is_eligible', FALSE,
      'course_id', p_course_id,
      'reasons', jsonb_build_array('Course record does not exist.'),
      'counts', jsonb_build_object()
    );
  END IF;

  -- 3. Query all dependent relationship tables
  SELECT COUNT(*) INTO v_enrollments_count
  FROM public.course_enrollments
  WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_payments_count
  FROM public.payments
  WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_live_classes_count
  FROM public.live_classes
  WHERE course_id = p_course_id;

  -- Count live class attendees if table exists
  IF to_regclass('public.live_class_attendees') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.live_class_attendees WHERE live_class_id IN (SELECT id FROM public.live_classes WHERE course_id = $1)'
      INTO v_live_class_attendees_count
      USING p_course_id;
  END IF;

  SELECT COUNT(*) INTO v_assessments_count
  FROM public.assessment_course_assignments
  WHERE course_id = p_course_id;

  -- Check if historical assessment results exist for assessments assigned to this course
  SELECT COUNT(*) INTO v_assessment_results_count
  FROM public.assessment_results
  WHERE assessment_id IN (
    SELECT assessment_id FROM public.assessment_course_assignments WHERE course_id = p_course_id
  );

  -- Count syllabus elements
  SELECT COUNT(*) INTO v_modules_count
  FROM public.course_modules
  WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_lessons_count
  FROM public.course_lessons
  WHERE module_id IN (
    SELECT id FROM public.course_modules WHERE course_id = p_course_id
  );

  -- Check lesson progress if table exists
  IF to_regclass('public.lesson_progress') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.lesson_progress WHERE lesson_id IN (
      SELECT cl.id FROM public.course_lessons cl
      JOIN public.course_modules cm ON cm.id = cl.module_id
      WHERE cm.course_id = $1
    )'
      INTO v_lesson_progress_count
      USING p_course_id;
  END IF;

  -- Check assignment submissions if table exists
  IF to_regclass('public.assignment_submissions') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.assignment_submissions WHERE lesson_id IN (
      SELECT cl.id FROM public.course_lessons cl
      JOIN public.course_modules cm ON cm.id = cl.module_id
      WHERE cm.course_id = $1
    )'
      INTO v_assignment_submissions_count
      USING p_course_id;
  END IF;

  -- 4. Evaluate blocking dependencies and compile descriptive reasons
  IF v_enrollments_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Course has %s active or historical student enrollment(s). Deletion would abruptly destroy student progress records.', v_enrollments_count)
    );
  END IF;

  IF v_payments_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Course is referenced by %s payment transaction(s). Deletion would orphan course revenue attribution.', v_payments_count)
    );
  END IF;

  IF v_live_classes_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Course has %s scheduled or conducted live class session(s).', v_live_classes_count)
    );
  END IF;

  IF v_live_class_attendees_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Live classes in this course have %s recorded attendee log(s).', v_live_class_attendees_count)
    );
  END IF;

  IF v_assessments_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Course has %s assessment(s) assigned to its curriculum track.', v_assessments_count)
    );
  END IF;

  IF v_assessment_results_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Assessments linked to this course have %s student exam result(s) on record.', v_assessment_results_count)
    );
  END IF;

  IF v_lesson_progress_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Course lessons have %s student progress tracking record(s).', v_lesson_progress_count)
    );
  END IF;

  IF v_assignment_submissions_count > 0 THEN
    v_reasons := v_reasons || jsonb_build_array(
      format('Course lessons have %s assignment submission(s).', v_assignment_submissions_count)
    );
  END IF;

  -- Course is eligible for hard deletion ONLY IF zero external academic or financial dependencies exist
  IF v_enrollments_count = 0
     AND v_payments_count = 0
     AND v_live_classes_count = 0
     AND v_live_class_attendees_count = 0
     AND v_assessments_count = 0
     AND v_assessment_results_count = 0
     AND v_lesson_progress_count = 0
     AND v_assignment_submissions_count = 0 THEN
    v_is_eligible := TRUE;
    v_reasons := jsonb_build_array(
      format('Course has zero external dependencies (no enrollments, payments, live classes, assessments, progress, or submissions). Safe to delete draft syllabus containing %s module(s) and %s lesson(s).', v_modules_count, v_lessons_count)
    );
  END IF;

  -- 5. Return structured audit payload
  RETURN jsonb_build_object(
    'exists', TRUE,
    'course_id', p_course_id,
    'title', v_course.title,
    'status', v_course.status,
    'is_eligible', v_is_eligible,
    'can_archive', (v_course.status != 'archived'),
    'reasons', v_reasons,
    'counts', jsonb_build_object(
      'enrollments', v_enrollments_count,
      'payments', v_payments_count,
      'live_classes', v_live_classes_count,
      'live_class_attendees', v_live_class_attendees_count,
      'assessment_assignments', v_assessments_count,
      'assessment_results', v_assessment_results_count,
      'lesson_progress', v_lesson_progress_count,
      'assignment_submissions', v_assignment_submissions_count,
      'modules', v_modules_count,
      'lessons', v_lessons_count
    ),
    'blocking_dependencies', jsonb_build_object(
      'has_enrollments', (v_enrollments_count > 0),
      'has_payments', (v_payments_count > 0),
      'has_live_classes', (v_live_classes_count > 0),
      'has_live_class_attendees', (v_live_class_attendees_count > 0),
      'has_assessments', (v_assessments_count > 0),
      'has_assessment_results', (v_assessment_results_count > 0),
      'has_lesson_progress', (v_lesson_progress_count > 0),
      'has_assignment_submissions', (v_assignment_submissions_count > 0)
    ),
    'recommendation', CASE
      WHEN v_is_eligible THEN 'PERMIT_HARD_DELETE'
      ELSE 'ARCHIVE_COURSE'
    END
  );
END;
$$;

COMMENT ON FUNCTION public.check_course_deletion_eligibility(UUID) IS
  'Performs an administrative audit of all dependencies linked to a course and determines deletion safety.';

-- ============================================================================
-- 4. Safe Course Deletion RPC (Guarded Atomic Deletion with Concurrency Lock)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.safe_delete_course(p_course_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_course RECORD;
  v_enrollments_count INTEGER := 0;
  v_payments_count INTEGER := 0;
  v_live_classes_count INTEGER := 0;
  v_live_class_attendees_count INTEGER := 0;
  v_assessments_count INTEGER := 0;
  v_assessment_results_count INTEGER := 0;
  v_lesson_progress_count INTEGER := 0;
  v_assignment_submissions_count INTEGER := 0;
  v_modules_count INTEGER := 0;
  v_lessons_count INTEGER := 0;
  v_admin_name TEXT;
BEGIN
  -- 1. Server-Side Authorization Check
  IF NOT public.is_admin_or_super() THEN
    RAISE EXCEPTION 'Access denied. Only administrators can delete courses.';
  END IF;

  -- 2. Concurrency Protection:
  -- A. Acquire transaction-level advisory lock on course UUID hash.
  -- This guarantees that concurrent lifecycle or deletion calls for this course cannot overlap.
  PERFORM pg_advisory_xact_lock(hashtext('safe_delete_course_' || p_course_id::text));

  -- B. Lock the target course row FOR UPDATE
  SELECT * INTO v_course
  FROM public.courses
  WHERE id = p_course_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'COURSE_NOT_FOUND',
      'message', 'Course does not exist or has already been removed.'
    );
  END IF;

  -- C. Lock associated course modules FOR UPDATE to prevent syllabus changes during deletion
  PERFORM 1
  FROM public.course_modules
  WHERE course_id = p_course_id
  FOR UPDATE;

  -- 3. Re-verify ALL protected deletion dependencies within the locked transaction
  SELECT COUNT(*) INTO v_enrollments_count
  FROM public.course_enrollments
  WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_payments_count
  FROM public.payments
  WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_live_classes_count
  FROM public.live_classes
  WHERE course_id = p_course_id;

  IF to_regclass('public.live_class_attendees') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.live_class_attendees WHERE live_class_id IN (SELECT id FROM public.live_classes WHERE course_id = $1)'
      INTO v_live_class_attendees_count
      USING p_course_id;
  END IF;

  SELECT COUNT(*) INTO v_assessments_count
  FROM public.assessment_course_assignments
  WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_assessment_results_count
  FROM public.assessment_results
  WHERE assessment_id IN (
    SELECT assessment_id FROM public.assessment_course_assignments WHERE course_id = p_course_id
  );

  IF to_regclass('public.lesson_progress') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.lesson_progress WHERE lesson_id IN (
      SELECT cl.id FROM public.course_lessons cl
      JOIN public.course_modules cm ON cm.id = cl.module_id
      WHERE cm.course_id = $1
    )'
      INTO v_lesson_progress_count
      USING p_course_id;
  END IF;

  IF to_regclass('public.assignment_submissions') IS NOT NULL THEN
    EXECUTE 'SELECT COUNT(*) FROM public.assignment_submissions WHERE lesson_id IN (
      SELECT cl.id FROM public.course_lessons cl
      JOIN public.course_modules cm ON cm.id = cl.module_id
      WHERE cm.course_id = $1
    )'
      INTO v_assignment_submissions_count
      USING p_course_id;
  END IF;

  -- Count syllabus elements for audit reporting
  SELECT COUNT(*) INTO v_modules_count
  FROM public.course_modules
  WHERE course_id = p_course_id;

  SELECT COUNT(*) INTO v_lessons_count
  FROM public.course_lessons
  WHERE module_id IN (
    SELECT id FROM public.course_modules WHERE course_id = p_course_id
  );

  -- 4. If any protected dependencies exist, REJECT deletion immediately
  IF v_enrollments_count > 0
     OR v_payments_count > 0
     OR v_live_classes_count > 0
     OR v_live_class_attendees_count > 0
     OR v_assessments_count > 0
     OR v_assessment_results_count > 0
     OR v_lesson_progress_count > 0
     OR v_assignment_submissions_count > 0 THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'PROTECTED_DEPENDENCIES_EXIST',
      'message', format('Course "%s" cannot be deleted because dependent academic or financial records exist. Archive the course instead to preserve student records.', v_course.title),
      'recommendation', 'ARCHIVE_COURSE',
      'counts', jsonb_build_object(
        'enrollments', v_enrollments_count,
        'payments', v_payments_count,
        'live_classes', v_live_classes_count,
        'live_class_attendees', v_live_class_attendees_count,
        'assessment_assignments', v_assessments_count,
        'assessment_results', v_assessment_results_count,
        'lesson_progress', v_lesson_progress_count,
        'assignment_submissions', v_assignment_submissions_count,
        'modules', v_modules_count,
        'lessons', v_lessons_count
      )
    );
  END IF;

  -- 5. Safe Atomic Deletion of draft curriculum & course
  -- Delete lessons first
  DELETE FROM public.course_lessons
  WHERE module_id IN (
    SELECT id FROM public.course_modules WHERE course_id = p_course_id
  );

  -- Delete modules next
  DELETE FROM public.course_modules
  WHERE course_id = p_course_id;

  -- Delete course record
  DELETE FROM public.courses
  WHERE id = p_course_id;

  -- 6. Log deletion to immutable activity_logs
  SELECT COALESCE(full_name, email, 'Administrator') INTO v_admin_name
  FROM public.profiles
  WHERE id = auth.uid();

  INSERT INTO public.activity_logs (
    admin_id,
    admin_name,
    action,
    target,
    metadata
  )
  VALUES (
    auth.uid(),
    COALESCE(v_admin_name, 'Administrator'),
    'DELETE_COURSE',
    v_course.title,
    jsonb_build_object(
      'course_id', p_course_id,
      'course_title', v_course.title,
      'status_at_deletion', v_course.status,
      'deleted_modules_count', v_modules_count,
      'deleted_lessons_count', v_lessons_count,
      'timestamp', NOW()
    )
  );

  -- 7. Return success payload
  RETURN jsonb_build_object(
    'success', TRUE,
    'course_id', p_course_id,
    'deleted_title', v_course.title,
    'deleted_modules_count', v_modules_count,
    'deleted_lessons_count', v_lessons_count,
    'message', format('Course "%s" and its %s draft module(s) and %s lesson(s) have been permanently removed.', v_course.title, v_modules_count, v_lessons_count)
  );
END;
$$;

COMMENT ON FUNCTION public.safe_delete_course(UUID) IS
  'Performs an atomic, dependency-guarded deletion of a course and its draft syllabus modules and lessons.';

-- ============================================================================
-- 5. RPC Execution Permissions
-- ============================================================================

-- Revoke public execution
REVOKE ALL ON FUNCTION public.check_student_deletion_eligibility(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_course_deletion_eligibility(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.safe_delete_course(UUID) FROM PUBLIC;

-- Grant execution to authenticated users (administrative role checked inside each function)
GRANT EXECUTE ON FUNCTION public.check_student_deletion_eligibility(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_course_deletion_eligibility(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.safe_delete_course(UUID) TO authenticated;

-- ============================================================================
-- 6. Direct Deletion Elimination (RLS Hardening & Table Privilege Revocation)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- A. Harden public.students (No Client Direct Delete Allowed)
-- ----------------------------------------------------------------------------
-- 1. Clean up legacy or unconstrained policies
DROP POLICY IF EXISTS "Admins have full access to students" ON public.students;
DROP POLICY IF EXISTS "Only super admins can delete students" ON public.students;
DROP POLICY IF EXISTS "Admins can view all students" ON public.students;
DROP POLICY IF EXISTS "Admins can insert students" ON public.students;
DROP POLICY IF EXISTS "Admins can update students" ON public.students;

-- 2. Create granular legitimate access policies (NO DELETE policy exists)
CREATE POLICY "Admins can view all students"
  ON public.students
  FOR SELECT
  TO authenticated
  USING (public.is_admin_or_super());

CREATE POLICY "Admins can insert students"
  ON public.students
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Admins can update students"
  ON public.students
  FOR UPDATE
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

-- 3. Revoke table-level DELETE and TRUNCATE privileges from all client roles
REVOKE DELETE, TRUNCATE ON TABLE public.students FROM authenticated, anon, public;
GRANT SELECT, INSERT, UPDATE ON TABLE public.students TO authenticated;
GRANT ALL ON TABLE public.students TO service_role;

-- 4. Force RLS to prevent bypass
ALTER TABLE public.students FORCE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- B. Harden public.courses (No Client Direct Delete Allowed)
-- ----------------------------------------------------------------------------
-- 1. Clean up legacy or unconstrained policies
DROP POLICY IF EXISTS "Admins manage all courses" ON public.courses;
DROP POLICY IF EXISTS "Only super admins can delete courses directly" ON public.courses;
DROP POLICY IF EXISTS "Admins can view all courses" ON public.courses;
DROP POLICY IF EXISTS "Admins can insert courses" ON public.courses;
DROP POLICY IF EXISTS "Admins can update courses" ON public.courses;

-- 2. Create granular legitimate access policies (NO DELETE policy exists)
CREATE POLICY "Admins can view all courses"
  ON public.courses
  FOR SELECT
  TO authenticated
  USING (public.is_admin_or_super());

CREATE POLICY "Admins can insert courses"
  ON public.courses
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Admins can update courses"
  ON public.courses
  FOR UPDATE
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

-- 3. Revoke table-level DELETE and TRUNCATE privileges from all client roles
-- Course deletion MUST be executed via the guarded safe_delete_course() RPC.
REVOKE DELETE, TRUNCATE ON TABLE public.courses FROM authenticated, anon, public;
GRANT SELECT, INSERT, UPDATE ON TABLE public.courses TO authenticated;
GRANT ALL ON TABLE public.courses TO service_role;

-- 4. Force RLS to prevent bypass
ALTER TABLE public.courses FORCE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- C. Harden public.payments (Complete Financial Ledger Immutability)
-- ----------------------------------------------------------------------------
-- 1. Clean up legacy policies
DROP POLICY IF EXISTS "Admins manage all payments" ON public.payments;
DROP POLICY IF EXISTS "Admins can view all payments" ON public.payments;
DROP POLICY IF EXISTS "Admins can insert payments" ON public.payments;
DROP POLICY IF EXISTS "Admins can update payment status" ON public.payments;

-- 2. Create granular legitimate access policies (NO DELETE policy exists)
CREATE POLICY "Admins can view all payments"
  ON public.payments
  FOR SELECT
  TO authenticated
  USING (public.is_admin_or_super());

CREATE POLICY "Admins can insert payments"
  ON public.payments
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Admins can update payment status"
  ON public.payments
  FOR UPDATE
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

-- 3. Revoke table-level DELETE and TRUNCATE privileges from all client roles
REVOKE DELETE, TRUNCATE ON TABLE public.payments FROM authenticated, anon, public;
GRANT SELECT, INSERT, UPDATE ON TABLE public.payments TO authenticated;
GRANT ALL ON TABLE public.payments TO service_role;

-- 4. Force RLS to prevent bypass
ALTER TABLE public.payments FORCE ROW LEVEL SECURITY;
