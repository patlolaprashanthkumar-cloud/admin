-- Migration: 20261114000001_add_student_delivery_format_and_cohort.sql
-- Description: Adds nullable learning_format and preferred_slot columns to public.students
--              with named check constraints and no database defaults.
--              Preserves all existing student records with NULL values (no backfill).

-- 1. Add columns to public.students safely if they do not already exist
DO $$
BEGIN
  -- Add learning_format column (TEXT, Nullable, No default)
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'students'
      AND column_name  = 'learning_format'
  ) THEN
    ALTER TABLE public.students
      ADD COLUMN learning_format TEXT;
  END IF;

  -- Add preferred_slot column (TEXT, Nullable, No default)
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'students'
      AND column_name  = 'preferred_slot'
  ) THEN
    ALTER TABLE public.students
      ADD COLUMN preferred_slot TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 2. Add named CHECK constraints to enforce allowed values while explicitly accepting NULL
DO $$
BEGIN
  -- Named check constraint for learning_format: 'hybrid', 'live', 'recorded' (or NULL)
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'chk_students_learning_format'
      AND conrelid = 'public.students'::regclass
  ) THEN
    ALTER TABLE public.students
      ADD CONSTRAINT chk_students_learning_format
      CHECK (
        learning_format IS NULL OR
        learning_format IN ('hybrid', 'live', 'recorded')
      );
  END IF;

  -- Named check constraint for preferred_slot: Morning, Evening, Weekend Intensive (or NULL)
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'chk_students_preferred_slot'
      AND conrelid = 'public.students'::regclass
  ) THEN
    ALTER TABLE public.students
      ADD CONSTRAINT chk_students_preferred_slot
      CHECK (
        preferred_slot IS NULL OR
        preferred_slot IN (
          'Morning Clinical Batch (08:00 - 10:00 IST)',
          'Evening Executive Batch (18:00 - 20:00 IST)',
          'Weekend Intensive (Saturday & Sunday)'
        )
      );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Documentation: Add SQL column comments explaining purpose and permitted values
COMMENT ON COLUMN public.students.learning_format IS
  'Selected learning delivery format for institutional training: hybrid, live, or recorded. Nullable with no database default.';

COMMENT ON COLUMN public.students.preferred_slot IS
  'Selected timetable cohort batch for clinical sessions: Morning Clinical Batch (08:00 - 10:00 IST), Evening Executive Batch (18:00 - 20:00 IST), or Weekend Intensive (Saturday & Sunday). Nullable with no database default.';
