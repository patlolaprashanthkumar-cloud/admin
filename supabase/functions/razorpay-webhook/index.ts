// Supabase Edge Function: razorpay-webhook
// Description: Receives and cryptographically verifies server-to-server Razorpay webhooks.
// Handles payment.captured, payment.failed, order.paid, refund.created, refund.processed, refund.failed.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';
import { crypto } from 'https://deno.land/std@0.177.0/crypto/mod.ts';

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  // Scoped outside try-catch to guarantee access in the error catch block
  let adminClient: any = null;
  let currentEventId: string | null = null;

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const webhookSecret = Deno.env.get('RAZORPAY_WEBHOOK_SECRET');
    const razorpayKeyId = Deno.env.get('RAZORPAY_KEY_ID');
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET');

    if (!supabaseUrl || !serviceRoleKey) {
      console.error('Server configuration missing: SUPABASE_URL or SERVICE_ROLE_KEY');
      return new Response(JSON.stringify({ error: 'Server misconfiguration' }), { status: 500 });
    }

    if (!webhookSecret) {
      console.error('RAZORPAY_WEBHOOK_SECRET is not configured');
      return new Response(JSON.stringify({ error: 'Webhook secret not configured' }), { status: 503 });
    }

    // 1. Verify Razorpay webhook signature header
    const signature = req.headers.get('x-razorpay-signature');
    if (!signature) {
      return new Response(JSON.stringify({ error: 'Missing x-razorpay-signature header' }), { status: 400 });
    }

    // 2. Read raw request body as text for HMAC verification
    const rawBody = await req.text();

    const encoder = new TextEncoder();
    const keyData = encoder.encode(webhookSecret);
    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );

    const signatureBuffer = await crypto.subtle.sign('HMAC', cryptoKey, encoder.encode(rawBody));
    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');

    if (!constantTimeEqual(expectedSignature, signature)) {
      console.error('Invalid Razorpay webhook signature. Request rejected.');
      return new Response(JSON.stringify({ error: 'Invalid webhook signature' }), { status: 400 });
    }

    // 3. Parse JSON event payload
    const event = JSON.parse(rawBody);
    const eventName = event.event;
    const eventId = event.id || req.headers.get('x-razorpay-event-id');

    // Strict validation: Never use Date.now() as an event ID substitute
    if (!eventId || typeof eventId !== 'string' || eventId.trim().length === 0) {
      console.error('Webhook payload missing event ID. Cannot ensure idempotency.');
      return new Response(JSON.stringify({ error: 'Missing x-razorpay-event-id or event.id in webhook' }), {
        status: 400,
      });
    }

    currentEventId = eventId;
    adminClient = createClient(supabaseUrl, serviceRoleKey);
    const now = new Date().toISOString();
    const payload = event.payload || {};

    console.log(`Processing Razorpay Webhook Event: ${eventName} (ID: ${eventId})`);

    // 4. Webhook Idempotency: Atomic claim via dedicated payment_webhook_events table
    // Attempt an immediate atomic insert to claim this delivery
    const { error: claimError } = await adminClient
      .from('payment_webhook_events')
      .insert({
        event_id: eventId,
        event_type: eventName,
        status: 'processing',
        created_at: now,
      });

    if (claimError) {
      // Event record already exists: inspect current status
      const { data: existingEvent, error: fetchErr } = await adminClient
        .from('payment_webhook_events')
        .select('*')
        .eq('event_id', eventId)
        .maybeSingle();

      if (existingEvent) {
        if (existingEvent.status === 'completed') {
          console.log(`Webhook event ${eventId} already completed. Returning safe 200 OK.`);
          return new Response(JSON.stringify({ status: 'ok', message: 'Already processed' }), { status: 200 });
        }

        const isStale =
          existingEvent.status === 'processing' &&
          Date.now() - new Date(existingEvent.created_at || existingEvent.processed_at || now).getTime() >
            5 * 60 * 1000;

        if (existingEvent.status === 'failed' || isStale) {
          // Atomically reclaim the failed or stale event for retry
          const { data: reclaimed, error: updateErr } = await adminClient
            .from('payment_webhook_events')
            .update({
              status: 'processing',
              error_message: null,
              created_at: now,
            })
            .eq('event_id', eventId)
            .eq('status', existingEvent.status)
            .select();

          if (!reclaimed || reclaimed.length === 0) {
            console.log(`Webhook event ${eventId} retry claimed concurrently by another worker.`);
            return new Response(
              JSON.stringify({ status: 'processing', message: 'Concurrent retry claim in progress' }),
              { status: 409, headers: { 'Content-Type': 'application/json' } }
            );
          }
          console.log(`Webhook event ${eventId} safely reclaimed for retry.`);
        } else {
          // Event is actively processing by another fresh worker (< 5 mins old)
          console.log(`Webhook event ${eventId} is currently in progress. Returning 409.`);
          return new Response(
            JSON.stringify({ status: 'processing', message: 'Event delivery currently in progress' }),
            { status: 409, headers: { 'Content-Type': 'application/json' } }
          );
        }
      } else {
        console.error('Failed to claim or fetch payment_webhook_events:', claimError);
        throw claimError;
      }
    }

    let processedPaymentRecordId: string | null = null;
    let processedOrderId: string | null = null;
    let eventProcessingSucceeded = false;
    let processingErrorMessage: string | null = null;

    // 5. Handle specific event types
    switch (eventName) {
      case 'payment.captured': {
        const paymentEntity = payload.payment?.entity;
        if (!paymentEntity) {
          processingErrorMessage = 'Payload missing payment entity';
          break;
        }

        const orderId = paymentEntity.order_id;
        const paymentId = paymentEntity.id;
        const currency = paymentEntity.currency;
        const gatewayStatus = paymentEntity.status;
        const amountPaise = paymentEntity.amount;

        if (!orderId) {
          processingErrorMessage = 'Payment entity missing order_id';
          break;
        }

        processedOrderId = orderId;

        // Locate existing payment strictly by order reference
        const { data: existingList, error: queryErr } = await adminClient
          .from('payments')
          .select('*')
          .or(`transaction_ref.eq.order_${orderId},raw_provider_payload->>razorpay_order_id.eq.${orderId}`);

        if (queryErr) throw queryErr;
        const existing = existingList && existingList.length > 0 ? existingList[0] : null;

        if (!existing) {
          processingErrorMessage = `Payment record not found for order ${orderId}`;
          console.warn(processingErrorMessage);
          break;
        }

        processedPaymentRecordId = existing.id;

        // Strict Order ID validation
        const storedOrderId = existing.raw_provider_payload?.razorpay_order_id;
        const isOrderMatch = storedOrderId === orderId || existing.transaction_ref === `order_${orderId}`;
        if (!isOrderMatch) {
          processingErrorMessage = `Security mismatch: order ID ${orderId} does not match stored payment ${existing.id}`;
          console.error(processingErrorMessage);
          break;
        }

        // Validate Currency and Amount (paise to INR exact matching)
        const expectedPaise = Math.round(Number(existing.amount) * 100);
        if (currency !== 'INR' || amountPaise !== expectedPaise) {
          processingErrorMessage = `Currency or amount mismatch for payment ${existing.id}: expected INR ${expectedPaise} paise, received ${currency} ${amountPaise} paise`;
          console.error(processingErrorMessage);
          break;
        }

        // Confirm gateway status is captured
        if (gatewayStatus !== 'captured') {
          processingErrorMessage = `Payment ${paymentId} is not captured on gateway (status: ${gatewayStatus})`;
          console.warn(processingErrorMessage);
          break;
        }

        // Terminal state guard: Never allow captured event to overwrite an already refunded payment
        if (existing.status === 'refunded' || existing.refund_status === 'completed') {
          console.warn(`Payment ${existing.id} is in terminal refunded state; skipping capture overwrite.`);
          eventProcessingSucceeded = true;
          break;
        }

        // Payment record idempotency
        const existingPayload = existing.raw_provider_payload || {};
        const processedEvents = (existingPayload.processed_webhook_events as string[]) || [];

        if (processedEvents.includes(eventId)) {
          console.log(`Webhook event ${eventId} already recorded on payment ${existing.id}`);
          eventProcessingSucceeded = true;
          break;
        }

        const receiptNum =
          existingPayload.receipt_number ||
          `IIECM-REC-${new Date().getFullYear()}-${paymentId.replace(/^pay_/, '')}`;

        // Concurrency-safe atomic database update
        const { error: updateErr } = await adminClient
          .from('payments')
          .update({
            status: 'verified',
            transaction_ref: paymentId,
            verified_by: 'Razorpay Webhook (payment.captured)',
            raw_provider_payload: {
              ...existingPayload,
              razorpay_payment_id: paymentId,
              razorpay_order_id: orderId,
              receipt_number: receiptNum,
              method: paymentEntity.method,
              captured_at: now,
              processed_webhook_events: [...processedEvents, eventId],
            },
            updated_at: now,
          })
          .eq('id', existing.id)
          .neq('status', 'refunded');

        if (updateErr) throw updateErr;

        eventProcessingSucceeded = true;
        break;
      }

      case 'payment.failed': {
        const paymentEntity = payload.payment?.entity;
        if (!paymentEntity) {
          processingErrorMessage = 'Payload missing payment entity';
          break;
        }

        const orderId = paymentEntity.order_id;
        const paymentId = paymentEntity.id;
        const reason =
          paymentEntity.error_description || paymentEntity.error_reason || 'Payment failed on gateway';

        if (!orderId) {
          processingErrorMessage = 'Payment entity missing order_id';
          break;
        }

        processedOrderId = orderId;

        const { data: existingList, error: queryErr } = await adminClient
          .from('payments')
          .select('*')
          .or(`transaction_ref.eq.order_${orderId},raw_provider_payload->>razorpay_order_id.eq.${orderId}`);

        if (queryErr) throw queryErr;
        const existing = existingList && existingList.length > 0 ? existingList[0] : null;

        if (!existing) {
          processingErrorMessage = `Payment record not found for order ${orderId}`;
          console.warn(processingErrorMessage);
          break;
        }

        processedPaymentRecordId = existing.id;

        // Strict Order ID validation
        const storedOrderId = existing.raw_provider_payload?.razorpay_order_id;
        const isOrderMatch = storedOrderId === orderId || existing.transaction_ref === `order_${orderId}`;
        if (!isOrderMatch) {
          processingErrorMessage = `Order ID mismatch on payment.failed: ${orderId} vs ${storedOrderId}`;
          console.error(processingErrorMessage);
          break;
        }

        // Terminal state guard: Never overwrite verified or refunded payment with a failure
        if (
          existing.status === 'verified' ||
          existing.status === 'refunded' ||
          existing.refund_status === 'completed'
        ) {
          console.log(`Payment ${existing.id} is already in state "${existing.status}"; ignoring late payment.failed.`);
          eventProcessingSucceeded = true;
          break;
        }

        const existingPayload = existing.raw_provider_payload || {};
        const processedEvents = (existingPayload.processed_webhook_events as string[]) || [];

        if (processedEvents.includes(eventId)) {
          console.log(`Webhook event ${eventId} already recorded on payment ${existing.id}`);
          eventProcessingSucceeded = true;
          break;
        }

        // Concurrency-safe atomic update: only transitions if payment is still pending
        const { error: updateErr } = await adminClient
          .from('payments')
          .update({
            status: 'failed',
            rejection_reason: reason,
            raw_provider_payload: {
              ...existingPayload,
              failed_payment_id: paymentId,
              error_code: paymentEntity.error_code,
              error_description: reason,
              processed_webhook_events: [...processedEvents, eventId],
            },
            updated_at: now,
          })
          .eq('id', existing.id)
          .eq('status', 'pending');

        if (updateErr) throw updateErr;

        eventProcessingSucceeded = true;
        break;
      }

      case 'order.paid': {
        const orderEntity = payload.order?.entity;
        processedOrderId = orderEntity?.id || null;
        console.log(`Order paid event acknowledged for order: ${processedOrderId}`);
        eventProcessingSucceeded = true;
        break;
      }

      case 'refund.created': {
        const refundEntity = payload.refund?.entity;
        if (!refundEntity) {
          processingErrorMessage = 'Payload missing refund entity';
          break;
        }

        const paymentId = refundEntity.payment_id;
        const refundId = refundEntity.id;
        const refundAmount = refundEntity.amount / 100;

        const { data: existingList, error: queryErr } = await adminClient
          .from('payments')
          .select('*')
          .or(`transaction_ref.eq.${paymentId},raw_provider_payload->>razorpay_payment_id.eq.${paymentId}`);

        if (queryErr) throw queryErr;
        const existing = existingList && existingList.length > 0 ? existingList[0] : null;

        if (!existing) {
          processingErrorMessage = `Payment record not found for refund payment ID ${paymentId}`;
          console.warn(processingErrorMessage);
          break;
        }

        processedPaymentRecordId = existing.id;
        const existingPayload = existing.raw_provider_payload || {};
        const processedEvents = (existingPayload.processed_webhook_events as string[]) || [];

        if (processedEvents.includes(eventId)) {
          eventProcessingSucceeded = true;
          break;
        }

        // Track initiated refund without prematurely marking full transaction as refunded
        const { error: updateErr } = await adminClient
          .from('payments')
          .update({
            refund_status: 'initiated',
            raw_provider_payload: {
              ...existingPayload,
              pending_refund_id: refundId,
              pending_refund_amount: refundAmount,
              refund_initiated_at: now,
              processed_webhook_events: [...processedEvents, eventId],
            },
            updated_at: now,
          })
          .eq('id', existing.id)
          .neq('status', 'refunded');

        if (updateErr) throw updateErr;

        eventProcessingSucceeded = true;
        break;
      }

      case 'refund.processed': {
        const refundEntity = payload.refund?.entity;
        if (!refundEntity) {
          processingErrorMessage = 'Payload missing refund entity';
          break;
        }

        const paymentId = refundEntity.payment_id;
        const refundId = refundEntity.id;
        const refundAmount = refundEntity.amount / 100;

        const { data: existingList, error: queryErr } = await adminClient
          .from('payments')
          .select('*')
          .or(`transaction_ref.eq.${paymentId},raw_provider_payload->>razorpay_payment_id.eq.${paymentId}`);

        if (queryErr) throw queryErr;
        const existing = existingList && existingList.length > 0 ? existingList[0] : null;

        if (!existing) {
          processingErrorMessage = `Payment record not found for refund payment ID ${paymentId}`;
          console.warn(processingErrorMessage);
          break;
        }

        processedPaymentRecordId = existing.id;
        const existingPayload = existing.raw_provider_payload || {};
        const processedEvents = (existingPayload.processed_webhook_events as string[]) || [];
        const processedRefundIds = (existingPayload.processed_refund_ids as string[]) || [];
        const existingRefundsHistory = (existingPayload.refunds_history as any[]) || [];

        // Deduplication: Guard against processing the exact same refund ID multiple times
        if (processedRefundIds.includes(refundId)) {
          console.log(`Refund ${refundId} has already been accounted for payment ${existing.id}`);
          eventProcessingSucceeded = true;
          break;
        }

        // Authoritatively retrieve all refunds for this payment from Razorpay API
        let authoritativeRefundTotal = 0;
        let rzpApiSuccess = false;

        if (razorpayKeyId && razorpayKeySecret) {
          try {
            const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);
            const rzpRefundsRes = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}/refunds`, {
              headers: { 'Authorization': `Basic ${basicAuth}` },
            });
            if (rzpRefundsRes.ok) {
              const rzpRefundsData = await rzpRefundsRes.json();
              const rzpItems = rzpRefundsData.items || [];
              authoritativeRefundTotal =
                rzpItems
                  .filter((r: any) => r.status === 'processed')
                  .reduce((acc: number, r: any) => acc + (Number(r.amount) || 0), 0) / 100;
              rzpApiSuccess = true;
            } else {
              console.warn(`Razorpay refunds API returned status ${rzpRefundsRes.status}`);
            }
          } catch (rzpErr) {
            console.warn('Could not query Razorpay refunds endpoint:', rzpErr);
          }
        }

        // If Razorpay API is unavailable, do NOT blindly increase without checking duplicate IDs
        if (!rzpApiSuccess) {
          const priorTotal = Number(existingPayload.total_refunded_amount) || 0;
          authoritativeRefundTotal = Math.min(Number(existing.amount), priorTotal + refundAmount);
        }

        const isFullRefund = authoritativeRefundTotal >= Number(existing.amount);

        const updatedRefundsHistory = [
          ...existingRefundsHistory,
          {
            refund_id: refundId,
            amount: refundAmount,
            status: 'processed',
            processed_at: now,
          },
        ];

        const { error: updateErr } = await adminClient
          .from('payments')
          .update({
            status: isFullRefund ? 'refunded' : existing.status,
            refund_status: 'completed',
            raw_provider_payload: {
              ...existingPayload,
              latest_refund_id: refundId,
              latest_refund_amount: refundAmount,
              total_refunded_amount: authoritativeRefundTotal,
              is_partial_refund: !isFullRefund,
              refund_processed_at: now,
              processed_refund_ids: [...processedRefundIds, refundId],
              processed_webhook_events: [...processedEvents, eventId],
              refunds_history: updatedRefundsHistory,
            },
            updated_at: now,
          })
          .eq('id', existing.id);

        if (updateErr) throw updateErr;

        eventProcessingSucceeded = true;
        break;
      }

      case 'refund.failed': {
        const refundEntity = payload.refund?.entity;
        if (!refundEntity) {
          processingErrorMessage = 'Payload missing refund entity';
          break;
        }

        const paymentId = refundEntity.payment_id;
        const refundId = refundEntity.id;
        const errorDesc =
          refundEntity.error_description || 'Refund processing failed on gateway';

        const { data: existingList, error: queryErr } = await adminClient
          .from('payments')
          .select('*')
          .or(`transaction_ref.eq.${paymentId},raw_provider_payload->>razorpay_payment_id.eq.${paymentId}`);

        if (queryErr) throw queryErr;
        const existing = existingList && existingList.length > 0 ? existingList[0] : null;

        if (!existing) {
          processingErrorMessage = `Payment record not found for failed refund payment ID ${paymentId}`;
          console.warn(processingErrorMessage);
          break;
        }

        processedPaymentRecordId = existing.id;
        const existingPayload = existing.raw_provider_payload || {};
        const failedRefunds = (existingPayload.failed_refund_attempts as any[]) || [];
        const processedEvents = (existingPayload.processed_webhook_events as string[]) || [];

        if (processedEvents.includes(eventId)) {
          eventProcessingSucceeded = true;
          break;
        }

        // If earlier partial refunds succeeded, refund_status remains 'completed'.
        // If this attempt failed and no prior refunds exist, set to 'rejected'
        // so payment is NOT left incorrectly marked as 'initiated'!
        const hasPriorCompletedRefunds = (Number(existingPayload.total_refunded_amount) || 0) > 0;
        const resolvedRefundStatus = hasPriorCompletedRefunds ? 'completed' : 'rejected';

        const { error: updateErr } = await adminClient
          .from('payments')
          .update({
            refund_status: resolvedRefundStatus,
            raw_provider_payload: {
              ...existingPayload,
              failed_refund_attempts: [
                ...failedRefunds,
                {
                  refund_id: refundId,
                  amount: refundEntity.amount / 100,
                  error_description: errorDesc,
                  failed_at: now,
                },
              ],
              processed_webhook_events: [...processedEvents, eventId],
            },
            updated_at: now,
          })
          .eq('id', existing.id);

        if (updateErr) throw updateErr;

        eventProcessingSucceeded = true;
        break;
      }

      default:
        console.log(`Unhandled webhook event: ${eventName}`);
        eventProcessingSucceeded = true;
        break;
    }

    // 6. Update dedicated payment_webhook_events table status
    if (!eventProcessingSucceeded) {
      const errMsg = processingErrorMessage || `Processing failed for event ${eventName}`;
      console.error(`Webhook processing incomplete: ${errMsg}`);
      await adminClient
        .from('payment_webhook_events')
        .update({
          status: 'failed',
          error_message: errMsg,
          processed_at: new Date().toISOString(),
        })
        .eq('event_id', eventId);

      return new Response(JSON.stringify({ error: errMsg }), { status: 422 });
    }

    // Mark completed ONLY when payment update succeeded
    await adminClient
      .from('payment_webhook_events')
      .update({
        status: 'completed',
        payment_id: processedPaymentRecordId,
        order_id: processedOrderId,
        processed_at: new Date().toISOString(),
      })
      .eq('event_id', eventId);

    return new Response(JSON.stringify({ status: 'ok', event: eventName }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Webhook handler error';
    console.error('Webhook error:', message);

    if (adminClient && currentEventId) {
      try {
        await adminClient
          .from('payment_webhook_events')
          .update({
            status: 'failed',
            error_message: message,
            processed_at: new Date().toISOString(),
          })
          .eq('event_id', currentEventId);
      } catch (statusUpdateErr) {
        console.error('Failed to record failed status in payment_webhook_events:', statusUpdateErr);
      }
    }

    return new Response(JSON.stringify({ error: message }), { status: 500 });
  }
});
