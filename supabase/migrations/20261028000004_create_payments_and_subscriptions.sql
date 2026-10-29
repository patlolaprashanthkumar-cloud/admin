-- Migration: 20261028000004_create_payments_and_subscriptions.sql
-- Description: Financial transactions, subscription plans, and student subscriptions with strict integrity

-- Payment Enums
DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pending', 'verified', 'rejected', 'failed', 'refunded');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_method AS ENUM ('razorpay', 'bank_transfer', 'upi', 'card', 'cash', 'cheque');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE refund_status AS ENUM ('none', 'initiated', 'completed', 'rejected');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Subscription Plans Table
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id subscription_plan PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL DEFAULT 0.00 CHECK (price >= 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  duration_months INTEGER NOT NULL DEFAULT 0 CHECK (duration_months >= 0),
  features TEXT[] NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default plans
INSERT INTO public.subscription_plans (id, name, price, duration_months, features, is_active)
VALUES
  ('free', 'Free Access', 0.00, 0, ARRAY['Browse course catalog', 'Preview lessons'], true),
  ('basic', 'Basic Plan', 4999.00, 6, ARRAY['1 course access', 'Recorded sessions', 'Community support'], true),
  ('premium', 'Premium Plan', 9999.00, 12, ARRAY['3 course access', 'Live + recorded sessions', 'Career guidance', 'Assessment access'], true),
  ('enterprise', 'Enterprise Plan', 24999.00, 12, ARRAY['Unlimited courses', 'Dedicated counsellor', 'Resume review', 'Mock interviews', 'Priority support'], true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_months = EXCLUDED.duration_months,
  features = EXCLUDED.features;

-- Student Subscriptions Table
CREATE TABLE IF NOT EXISTS public.student_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  plan subscription_plan NOT NULL REFERENCES public.subscription_plans(id),
  status subscription_status NOT NULL DEFAULT 'pending',
  start_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_student_subscriptions_updated_at ON public.student_subscriptions;
CREATE TRIGGER trg_student_subscriptions_updated_at
  BEFORE UPDATE ON public.student_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Payments Table (Strict transactionRef uniqueness)
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_ref TEXT NOT NULL UNIQUE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL,
  course_name TEXT,
  subscription_plan subscription_plan REFERENCES public.subscription_plans(id),
  amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  payment_method payment_method NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verified_by TEXT,
  rejection_reason TEXT,
  refund_status refund_status NOT NULL DEFAULT 'none',
  subscription_start TIMESTAMPTZ,
  subscription_expiry TIMESTAMPTZ,
  notes TEXT,
  raw_provider_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_payments_updated_at ON public.payments;
CREATE TRIGGER trg_payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_payments_student_id ON public.payments(student_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON public.payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_ref ON public.payments(transaction_ref);
CREATE INDEX IF NOT EXISTS idx_student_subscriptions_student ON public.student_subscriptions(student_id);

-- Enable RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Plans Policies
CREATE POLICY "Public read subscription plans" ON public.subscription_plans FOR SELECT USING (true);
CREATE POLICY "Admins manage subscription plans" ON public.subscription_plans FOR ALL TO authenticated USING (public.is_admin_or_super()) WITH CHECK (public.is_admin_or_super());

-- Student Subscriptions Policies
CREATE POLICY "Admins manage all student subscriptions"
  ON public.student_subscriptions
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Students view their own subscriptions"
  ON public.student_subscriptions
  FOR SELECT
  TO authenticated
  USING (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

-- Payments Policies
CREATE POLICY "Admins manage all payments"
  ON public.payments
  FOR ALL
  TO authenticated
  USING (public.is_admin_or_super())
  WITH CHECK (public.is_admin_or_super());

CREATE POLICY "Students view their own payment transactions"
  ON public.payments
  FOR SELECT
  TO authenticated
  USING (student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid()));

CREATE POLICY "Students can submit initial pending payment proofs"
  ON public.payments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id IN (SELECT id FROM public.students WHERE profile_id = auth.uid())
    AND status = 'pending'
  );

