// Supabase Edge Function: verify-payment
// Description: Validates server-side payment provider signatures (e.g. Razorpay) before updating records

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';
import { crypto } from 'https://deno.land/std@0.177.0/crypto/mod.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface VerifyPaymentPayload {
  paymentId: string;
  provider: 'razorpay' | 'upi_reference';
  razorpayOrderId?: string;
  razorpayPaymentId?: string;
  razorpaySignature?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET');

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: 'Server configuration missing' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Authorization header required' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const payload: VerifyPaymentPayload = await req.json();

    if (!payload.paymentId) {
      return new Response(JSON.stringify({ error: 'paymentId is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Retrieve existing payment record
    const { data: payment, error: fetchError } = await adminClient
      .from('payments')
      .select('*')
      .eq('id', payload.paymentId)
      .single();

    if (fetchError || !payment) {
      return new Response(JSON.stringify({ error: 'Payment transaction record not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (payment.status === 'verified') {
      return new Response(JSON.stringify({ message: 'Payment has already been verified', payment }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Razorpay cryptographic verification
    if (payload.provider === 'razorpay') {
      if (!razorpayKeySecret) {
        return new Response(
          JSON.stringify({
            error: 'Payment provider secrets not configured on server (RAZORPAY_KEY_SECRET). Live verification incomplete.',
            status: 'PROVIDER_CONFIG_REQUIRED',
          }),
          { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = payload;
      if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
        return new Response(JSON.stringify({ error: 'Missing Razorpay verification tokens (order_id, payment_id, signature)' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Compute HMAC SHA256 signature
      const textToSign = `${razorpayOrderId}|${razorpayPaymentId}`;
      const encoder = new TextEncoder();
      const keyData = encoder.encode(razorpayKeySecret);
      const cryptoKey = await crypto.subtle.importKey(
        'raw',
        keyData,
        { name: 'HMAC', hash: 'SHA-256' },
        false,
        ['sign']
      );

      const signatureBuffer = await crypto.subtle.sign('HMAC', cryptoKey, encoder.encode(textToSign));
      const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');

      if (expectedSignature !== razorpaySignature) {
        // Mark payment failed due to signature forgery
        await adminClient.from('payments').update({
          status: 'failed',
          rejection_reason: 'HMAC Signature verification failed',
          updated_at: new Date().toISOString(),
        }).eq('id', payload.paymentId);

        return new Response(JSON.stringify({ error: 'Invalid payment signature. Verification failed.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    // Payment signature successfully verified: Update status to verified
    const now = new Date();
    const expiryDate = new Date();
    expiryDate.setFullYear(now.getFullYear() + 1);

    const { data: updatedPayment, error: updateError } = await adminClient
      .from('payments')
      .update({
        status: 'verified',
        verified_by: 'Server Verified (verify-payment)',
        subscription_start: now.toISOString(),
        subscription_expiry: expiryDate.toISOString(),
        raw_provider_payload: payload,
        updated_at: now.toISOString(),
      })
      .eq('id', payload.paymentId)
      .select()
      .single();

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Activate student subscription
    if (payment.student_id && payment.subscription_plan) {
      await adminClient
        .from('students')
        .update({
          subscription_plan: payment.subscription_plan,
          subscription_status: 'active',
          subscription_start: now.toISOString(),
          subscription_expiry: expiryDate.toISOString(),
          updated_at: now.toISOString(),
        })
        .eq('id', payment.student_id);

      // Upsert student_subscriptions record
      await adminClient
        .from('student_subscriptions')
        .insert({
          student_id: payment.student_id,
          plan: payment.subscription_plan,
          status: 'active',
          start_date: now.toISOString(),
          expiry_date: expiryDate.toISOString(),
        });
    }

    // Audit log
    await adminClient.from('activity_logs').insert({
      admin_name: 'Payment System',
      action: 'Verified payment',
      target: `TXN: ${payment.transaction_ref} - Amount: ₹${payment.amount}`,
      timestamp: now.toISOString(),
      metadata: { paymentId: payment.id, studentId: payment.student_id },
    });

    return new Response(JSON.stringify({ success: true, payment: updatedPayment }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown server error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

