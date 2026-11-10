// Supabase Edge Function: verify-razorpay-payment
// Description: Cryptographically verifies Razorpay HMAC SHA-256 signature, validates payment capture
// against Razorpay API, prevents duplicate processing, and marks transaction as verified.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';
import { crypto } from 'https://deno.land/std@0.177.0/crypto/mod.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface VerifyPaymentPayload {
  paymentId?: string;
  razorpayPaymentId: string;
  razorpayOrderId: string;
  razorpaySignature: string;
}

/**
 * Constant-time string comparison to prevent timing attacks
 */
function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const razorpayKeyId = Deno.env.get('RAZORPAY_KEY_ID');
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET');

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: 'Server configuration missing' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!razorpayKeyId || !razorpayKeySecret) {
      return new Response(
        JSON.stringify({
          error: 'Razorpay secrets not configured on server (RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET).',
          status: 'CONFIG_REQUIRED',
        }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Authenticate caller
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header is required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const token = authHeader.replace(/^Bearer\s+/i, '');
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: { user }, error: authError } = await adminClient.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Authentication failed or session expired' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Authorize caller: Validate role from public.profiles
    const { data: profile, error: profileError } = await adminClient
      .from('profiles')
      .select('id, role, full_name, email')
      .eq('id', user.id)
      .single();

    if (profileError || !profile || !['admin', 'super_admin'].includes(profile.role)) {
      return new Response(
        JSON.stringify({ error: 'Forbidden: Admin or Super-Admin role required to verify payments' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Parse and validate payload
    const payload: VerifyPaymentPayload = await req.json();
    const { paymentId, razorpayPaymentId, razorpayOrderId, razorpaySignature } = payload;

    if (!razorpayPaymentId || !razorpayOrderId || !razorpaySignature) {
      return new Response(
        JSON.stringify({
          error: 'Missing required Razorpay verification parameters (razorpayPaymentId, razorpayOrderId, razorpaySignature)',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 4. Locate existing payment record strictly by paymentId or order transaction reference
    let paymentQuery = adminClient.from('payments').select('*');
    if (paymentId) {
      paymentQuery = paymentQuery.eq('id', paymentId);
    } else {
      paymentQuery = paymentQuery.eq('transaction_ref', `order_${razorpayOrderId}`);
    }

    const { data: paymentRecords, error: fetchError } = await paymentQuery;
    const payment = paymentRecords && paymentRecords.length > 0 ? paymentRecords[0] : null;

    if (fetchError || !payment) {
      return new Response(
        JSON.stringify({ error: 'Corresponding payment record not found for this Razorpay order' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 5. Strict Association Guard: Stored order ID or transaction reference must match razorpayOrderId
    const storedOrderId = payment.raw_provider_payload?.razorpay_order_id;
    const isOrderMatch =
      storedOrderId === razorpayOrderId ||
      payment.transaction_ref === `order_${razorpayOrderId}`;

    if (!isOrderMatch) {
      return new Response(
        JSON.stringify({
          error: 'Security mismatch: Payment record does not belong to the supplied Razorpay order ID',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 6. Terminal State Guard: Never overwrite a refunded payment
    if (payment.status === 'refunded' || payment.refund_status === 'completed') {
      return new Response(
        JSON.stringify({
          error: 'Payment cannot be verified because it has already reached terminal refunded state.',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 7. Idempotency: If already verified, return safely without duplicating receipts
    if (payment.status === 'verified') {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Payment has already been verified and recorded.',
          payment,
          receiptNumber: payment.raw_provider_payload?.receipt_number || payment.transaction_ref,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 8. Compute HMAC SHA-256 signature
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

    // Constant-time comparison
    const isSignatureValid = constantTimeEqual(expectedSignature, razorpaySignature);
    if (!isSignatureValid) {
      console.warn(`Cryptographic signature mismatch for payment ${payment.id}, order ${razorpayOrderId}`);
      // Do NOT mark payment failed in database on bad signature to prevent denial-of-service / forged failures
      return new Response(
        JSON.stringify({ error: 'Cryptographic signature verification failed' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 9. Query Razorpay API to confirm capture status, amount, and order ID
    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);
    const rzpRes = await fetch(`https://api.razorpay.com/v1/payments/${razorpayPaymentId}`, {
      headers: {
        'Authorization': `Basic ${basicAuth}`,
      },
    });

    if (!rzpRes.ok) {
      return new Response(
        JSON.stringify({ error: 'Failed to verify payment status with Razorpay API' }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const rzpPayment = await rzpRes.json();

    // Verify order ID match
    if (rzpPayment.order_id !== razorpayOrderId) {
      return new Response(
        JSON.stringify({ error: 'Payment does not belong to the referenced Razorpay order' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify currency
    if (rzpPayment.currency !== 'INR') {
      return new Response(
        JSON.stringify({ error: `Invalid currency: expected INR, got ${rzpPayment.currency}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify exact amount matching (paise to INR)
    const expectedPaise = Math.round(Number(payment.amount) * 100);
    if (rzpPayment.amount !== expectedPaise) {
      return new Response(
        JSON.stringify({
          error: `Paid amount (₹${rzpPayment.amount / 100}) does not match expected amount (₹${payment.amount})`,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify status is captured (or capture and re-verify if authorized)
    let finalRzpPayment = rzpPayment;
    if (rzpPayment.status !== 'captured') {
      if (rzpPayment.status === 'authorized') {
        // Attempt automatic capture
        const captureRes = await fetch(`https://api.razorpay.com/v1/payments/${razorpayPaymentId}/capture`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${basicAuth}`,
          },
          body: JSON.stringify({ amount: rzpPayment.amount, currency: 'INR' }),
        });
        if (!captureRes.ok) {
          return new Response(
            JSON.stringify({ error: 'Payment authorized on gateway but automatic capture failed' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        // Re-retrieve payment from Razorpay and confirm final captured status
        const refetchRes = await fetch(`https://api.razorpay.com/v1/payments/${razorpayPaymentId}`, {
          headers: { 'Authorization': `Basic ${basicAuth}` },
        });

        if (!refetchRes.ok) {
          return new Response(
            JSON.stringify({ error: 'Failed to re-fetch payment status from Razorpay after capture attempt' }),
            { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        finalRzpPayment = await refetchRes.json();
        if (finalRzpPayment.status !== 'captured') {
          return new Response(
            JSON.stringify({ error: `Payment could not be confirmed as captured (status: ${finalRzpPayment.status})` }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
      } else {
        return new Response(
          JSON.stringify({
            error: `Payment is not in captured state (current status: ${rzpPayment.status})`,
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // 10. Update payment record safely with atomic race-condition guard
    const now = new Date();
    const receiptNumber = `IIECM-REC-${now.getFullYear()}-${razorpayPaymentId.replace(/^pay_/, '')}`;

    const existingPayload = payment.raw_provider_payload || {};
    const updatedPayload = {
      ...existingPayload,
      razorpay_payment_id: razorpayPaymentId,
      razorpay_order_id: razorpayOrderId,
      razorpay_signature: razorpaySignature,
      receipt_number: receiptNumber,
      payment_method_type: finalRzpPayment.method, // upi, card, netbanking, wallet
      bank: finalRzpPayment.bank || null,
      wallet: finalRzpPayment.wallet || null,
      vpa: finalRzpPayment.vpa || null,
      card: finalRzpPayment.card ? {
        network: finalRzpPayment.card.network,
        type: finalRzpPayment.card.type,
        last4: finalRzpPayment.card.last4,
      } : null,
      fee_paise: finalRzpPayment.fee,
      tax_paise: finalRzpPayment.tax,
      verified_at: now.toISOString(),
      verified_by: 'Server Razorpay Verified',
    };

    // Atomic update condition: Only update if status is still not verified or refunded
    const { data: updatedPayment, error: updateError } = await adminClient
      .from('payments')
      .update({
        status: 'verified',
        transaction_ref: razorpayPaymentId, // Unique payment reference
        verified_by: 'Server Razorpay Gateway',
        raw_provider_payload: updatedPayload,
        updated_at: now.toISOString(),
      })
      .eq('id', payment.id)
      .neq('status', 'verified')
      .neq('status', 'refunded')
      .select()
      .maybeSingle();

    if (updateError) {
      return new Response(
        JSON.stringify({ error: `Database update failed: ${updateError.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // If another concurrent request already completed the verification transition
    if (!updatedPayment) {
      const { data: currentPayment } = await adminClient
        .from('payments')
        .select('*')
        .eq('id', payment.id)
        .single();

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Payment verified concurrently by another request',
          payment: currentPayment || payment,
          receiptNumber: currentPayment?.raw_provider_payload?.receipt_number || receiptNumber,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 11. Only the single winning transition activates subscription (with duplicate guard)
    if (payment.student_id && payment.subscription_plan) {
      const { data: existingSub } = await adminClient
        .from('student_subscriptions')
        .select('id')
        .eq('student_id', payment.student_id)
        .eq('plan', payment.subscription_plan)
        .eq('status', 'active')
        .maybeSingle();

      if (!existingSub) {
        const expiry = new Date(now);
        expiry.setFullYear(expiry.getFullYear() + 1);

        await adminClient.from('students').update({
          subscription_plan: payment.subscription_plan,
          subscription_status: 'active',
          subscription_start: now.toISOString(),
          subscription_expiry: expiry.toISOString(),
          updated_at: now.toISOString(),
        }).eq('id', payment.student_id);

        await adminClient.from('student_subscriptions').insert({
          student_id: payment.student_id,
          plan: payment.subscription_plan,
          status: 'active',
          start_date: now.toISOString(),
          expiry_date: expiry.toISOString(),
        });
      }
    }

    // 12. Activity log: Logged exactly once by winning worker
    await adminClient.from('activity_logs').insert({
      admin_name: user.email || 'Admin',
      action: 'Verified Razorpay Payment',
      target: `TXN: ${razorpayPaymentId} - ₹${payment.amount}`,
      timestamp: now.toISOString(),
      metadata: {
        paymentId: payment.id,
        orderId: razorpayOrderId,
        amount: payment.amount,
        studentId: payment.student_id,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        payment: updatedPayment,
        receiptNumber: receiptNumber,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Server error during payment verification';
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
