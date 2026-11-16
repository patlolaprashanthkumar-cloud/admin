-- Migration: 20261116000001_add_live_recorded_learning_format.sql
-- Description: Updates the chk_students_learning_format CHECK constraint on public.students
--              to include 'live_recorded' alongside 'hybrid', 'live', and 'recorded'.
--              Preserves NULLability, preferred_slot constraint, and all existing student records.

DO $$
BEGIN
  -- 1. Drop existing CHECK constraint if present on public.students
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'chk_students_learning_format'
      AND conrelid = 'public.students'::regclass
  ) THEN
    ALTER TABLE public.students
      DROP CONSTRAINT chk_students_learning_format;
  END IF;

  -- 2. Add updated CHECK constraint including 'live_recorded'
  ALTER TABLE public.students
    ADD CONSTRAINT chk_students_learning_format
    CHECK (
      learning_format IS NULL OR
      learning_format IN ('hybrid', 'live', 'recorded', 'live_recorded')
    );
END;
$$ LANGUAGE plpgsql;

-- 3. Update SQL column comment to document all 4 permitted delivery formats
COMMENT ON COLUMN public.students.learning_format IS
  'Selected learning delivery format for institutional training: hybrid, live, recorded, or live_recorded. Nullable with no database default.';
