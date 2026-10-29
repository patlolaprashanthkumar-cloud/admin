-- Migration: 20261028000010_add_is_active_to_course_categories.sql
-- Description: Add missing `is_active` flag (and helper trigger) to the
--              existing `course_categories` table.

-- ----------------------------------------------------------------------
-- 1️⃣ Add the column if it doesn’t already exist
-- ----------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'course_categories'
      AND column_name  = 'is_active'
  ) THEN
    ALTER TABLE public.course_categories
      ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------
-- 2️⃣ Re‑create the “public_read_active” policy (it now references the column)
-- ----------------------------------------------------------------------
-- First drop the old policy if it exists (it would have failed earlier)
DROP POLICY IF EXISTS public_read_active ON public.course_categories;

CREATE POLICY "public_read_active"
  ON public.course_categories
  FOR SELECT
  USING (is_active = true);

-- ----------------------------------------------------------------------
-- 3️⃣ Ensure the `updated_at` trigger still works (re‑create it if missing)
-- ----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_course_category_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_update_course_category_timestamp
  ON public.course_categories;

CREATE TRIGGER trg_update_course_category_timestamp
BEFORE UPDATE ON public.course_categories
FOR EACH ROW
EXECUTE FUNCTION public.update_course_category_timestamp();

-- ----------------------------------------------------------------------
-- 4️⃣ (Optional) Add an index on the new column for fast filtering
-- ----------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_course_categories_is_active
  ON public.course_categories (is_active);
