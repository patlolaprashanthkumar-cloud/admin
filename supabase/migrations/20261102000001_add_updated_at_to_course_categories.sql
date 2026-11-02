-- Migration: 20261102000001_add_updated_at_to_course_categories.sql
-- Description: Add missing updated_at column to public.course_categories
--              and fix trigger trg_update_course_category_timestamp.

-- 1. Add missing updated_at column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'course_categories'
      AND column_name  = 'updated_at'
  ) THEN
    ALTER TABLE public.course_categories
      ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 2. Update trigger function
CREATE OR REPLACE FUNCTION public.update_course_category_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Recreate the trigger
DROP TRIGGER IF EXISTS trg_update_course_category_timestamp
  ON public.course_categories;

CREATE TRIGGER trg_update_course_category_timestamp
BEFORE UPDATE ON public.course_categories
FOR EACH ROW
EXECUTE FUNCTION public.update_course_category_timestamp();

