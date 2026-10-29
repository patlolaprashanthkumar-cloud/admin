-- Migration: 20261028000008_create_activity_logs.sql
-- Description: Administrative audit trail and immutable activity logs

-- Activity Logs Table
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_name TEXT NOT NULL,
  action TEXT NOT NULL,
  target TEXT NOT NULL,
  ip_address TEXT,
  metadata JSONB NOT NULL DEFAULT '{}',
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for timeline queries
CREATE INDEX IF NOT EXISTS idx_activity_logs_timestamp ON public.activity_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_admin_id ON public.activity_logs(admin_id);

-- Enable RLS
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Activity Logs Policies:
-- Only super admins and administrators can view activity logs
CREATE POLICY "Admins view activity logs"
  ON public.activity_logs
  FOR SELECT
  TO authenticated
  USING (public.is_admin_or_super());

-- Admins and system processes can append logs
CREATE POLICY "Admins insert activity logs"
  ON public.activity_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_super());

-- Immutable: Prevent UPDATE and DELETE operations
CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Audit trail logs are immutable and cannot be updated or deleted.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_log_update ON public.activity_logs;
CREATE TRIGGER trg_prevent_log_update
  BEFORE UPDATE OR DELETE ON public.activity_logs
  FOR EACH ROW
  EXECUTE FUNCTION prevent_audit_log_modification();

