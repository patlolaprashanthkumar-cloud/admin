// Supabase Edge Function: create-razorpay-order
// Description: Authenticates admin, validates authoritative fee balances, creates official Razorpay Order,
// and records a pending payment transaction.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface CreateOrderPayload {
  studentId: string;
  courseId?: string;
  amount: number;
  notes?: string;
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
        JSON.stringify({ error: 'Server configuration missing: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!razorpayKeyId || !razorpayKeySecret) {
      return new Response(
        JSON.stringify({
          error: 'Razorpay credentials not configured. Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in Supabase secrets.',
          status: 'CONFIG_REQUIRED',
        }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Authenticate caller using JWT
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
        JSON.stringify({ error: 'Invalid authentication session or token expired' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Verify admin / super_admin role
    const { data: profile, error: profileError } = await adminClient
      .from('profiles')
      .select('role, full_name, email')
      .eq('id', user.id)
      .single();

    if (profileError || !profile || !['admin', 'super_admin'].includes(profile.role)) {
      return new Response(
        JSON.stringify({ error: 'Forbidden: Admin privileges required to initiate gateway orders' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Parse and validate input payload
    const payload: CreateOrderPayload = await req.json();
    const { studentId, courseId, amount, notes } = payload;

    if (!studentId || typeof studentId !== 'string') {
      return new Response(
        JSON.stringify({ error: 'studentId is required and must be a valid ID' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Amount must be finite, strictly positive, and valid to at most 2 decimal places
    if (
      typeof amount !== 'number' ||
      !Number.isFinite(amount) ||
      amount <= 0 ||
      Math.abs(Math.round(amount * 100) - amount * 100) > 1e-6
    ) {
      return new Response(
        JSON.stringify({
          error: 'Amount must be a positive finite numeric value with at most two decimal places (e.g. 5000 or 5000.50)',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 4. Validate Student existence
    const { data: student, error: studentError } = await adminClient
      .from('students')
      .select('id, full_name, student_id, email, phone')
      .eq('id', studentId)
      .single();

    if (studentError || !student) {
      return new Response(
        JSON.stringify({ error: 'Student not found in institutional records' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 5. Authoritative Fee Balance & Enrollment Validation
    let courseData: { id: string; title: string; fee: number } | null = null;
    let expectedMaxBalance = 0;

    // Helper: calculate net paid amount considering partial and full refunds
    const calculateNetPaid = (p: any): number => {
      if (p.status !== 'verified') return 0;
      const amt = Number(p.amount) || 0;
      if (p.status === 'refunded' || p.refund_status === 'completed') {
        const refunded = Number(p.raw_provider_payload?.total_refunded_amount || amt);
        return Math.max(0, amt - refunded);
      }
      return amt;
    };

    // Calculate total student institutional fees across all enrolled courses
    const { data: allEnrollments } = await adminClient
      .from('course_enrollments')
      .select('course_id, courses(id, fee)')
      .eq('student_id', studentId);

    const totalInstitutionalFees = (allEnrollments || []).reduce((acc: number, e: any) => {
      const fee = Number(e.courses?.fee) || 0;
      return acc + fee;
    }, 0);

    const { data: allStudentPayments } = await adminClient
      .from('payments')
      .select('amount, status, refund_status, raw_provider_payload')
      .eq('student_id', studentId)
      .eq('status', 'verified');

    const totalInstitutionalNetPaid = (allStudentPayments || []).reduce(
      (acc: number, p: any) => acc + calculateNetPaid(p),
      0
    );
    const institutionalOutstandingBalance = Math.max(0, totalInstitutionalFees - totalInstitutionalNetPaid);

    if (courseId) {
      // 5a. Verify enrollment in course
      const { data: enrollment, error: enrollError } = await adminClient
        .from('course_enrollments')
        .select('id, status')
        .eq('student_id', studentId)
        .eq('course_id', courseId)
        .maybeSingle();

      if (enrollError || !enrollment) {
        return new Response(
          JSON.stringify({ error: 'Student is not enrolled in the specified course' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const { data: course, error: courseError } = await adminClient
        .from('courses')
        .select('id, title, fee')
        .eq('id', courseId)
        .single();

      if (courseError || !course) {
        return new Response(
          JSON.stringify({ error: 'Selected course not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      courseData = { id: course.id, title: course.title, fee: Number(course.fee) || 0 };

      // Compute total net verified payments made specifically for this course
      const { data: coursePayments } = await adminClient
        .from('payments')
        .select('amount, status, refund_status, raw_provider_payload')
        .eq('student_id', studentId)
        .eq('course_id', courseId)
        .eq('status', 'verified');

      const courseAlreadyPaid = (coursePayments || []).reduce(
        (acc: number, p: any) => acc + calculateNetPaid(p),
        0
      );
      expectedMaxBalance = Math.max(0, courseData.fee - courseAlreadyPaid);

      if (amount > expectedMaxBalance) {
        return new Response(
          JSON.stringify({
            error: `Requested amount (₹${amount}) exceeds the remaining balance for "${courseData.title}" (₹${expectedMaxBalance})`,
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      if (amount > institutionalOutstandingBalance) {
        return new Response(
          JSON.stringify({
            error: `Requested amount (₹${amount}) exceeds the student's total outstanding institutional balance (₹${institutionalOutstandingBalance})`,
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    } else {
      // 5b. General Institutional Program Fee: Cap at institutional outstanding balance
      expectedMaxBalance = institutionalOutstandingBalance;

      if (amount > expectedMaxBalance) {
        return new Response(
          JSON.stringify({
            error: `Requested amount (₹${amount}) exceeds the student's total institutional balance (₹${expectedMaxBalance})`,
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // 6. Convert amount to paise (1 INR = 100 paise)
    const amountPaise = Math.round(amount * 100);
    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);

    // 7. Idempotency & Order Reuse: Check for active, unpaid Razorpay order created in last 15 minutes
    const fifteenMinsAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString();
    let pendingQuery = adminClient
      .from('payments')
      .select('*')
      .eq('student_id', studentId)
      .eq('payment_method', 'razorpay')
      .eq('status', 'pending')
      .eq('amount', amount)
      .eq('currency', 'INR')
      .gte('created_at', fifteenMinsAgo);

    if (courseId) {
      pendingQuery = pendingQuery.eq('course_id', courseId);
    } else {
      pendingQuery = pendingQuery.is('course_id', null);
    }

    const { data: recentPendingOrders } = await pendingQuery;
    if (recentPendingOrders && recentPendingOrders.length > 0) {
      const activePending = recentPendingOrders[0];
      const existingOrderId = activePending.raw_provider_payload?.razorpay_order_id;

      if (existingOrderId) {
        // Authoritatively verify order status with Razorpay API before reusing
        try {
          const rzpOrderCheck = await fetch(`https://api.razorpay.com/v1/orders/${existingOrderId}`, {
            headers: { 'Authorization': `Basic ${basicAuth}` },
          });

          if (rzpOrderCheck.ok) {
            const rzpOrderData = await rzpOrderCheck.json();
            const rzpNotes = rzpOrderData.notes || {};

            // Strictly verify that student, course, amount, currency, and open status ALL match
            const studentMatches =
              activePending.student_id === studentId &&
              (!rzpNotes.student_id || rzpNotes.student_id === studentId);

            const courseMatches = courseId
              ? (activePending.course_id === courseId && rzpNotes.course_id === courseId)
              : (!activePending.course_id && (!rzpNotes.course_id || rzpNotes.course_id === 'general'));

            const amountMatches =
              Number(activePending.amount) === amount &&
              rzpOrderData.amount === amountPaise;

            const currencyMatches =
              activePending.currency === 'INR' &&
              rzpOrderData.currency === 'INR';

            const statusMatches =
              rzpOrderData.status === 'created' &&
              Number(rzpOrderData.amount_paid) === 0;

            if (studentMatches && courseMatches && amountMatches && currencyMatches && statusMatches) {
              return new Response(
                JSON.stringify({
                  success: true,
                  isReusedOrder: true,
                  paymentId: activePending.id,
                  orderId: existingOrderId,
                  amountPaise: amountPaise,
                  amountInr: amount,
                  currency: 'INR',
                  keyId: razorpayKeyId,
                  student: {
                    id: student.id,
                    code: student.student_id,
                    name: student.full_name,
                    email: student.email,
                    phone: student.phone,
                  },
                  course: courseData,
                }),
                { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
              );
            }
          }
        } catch (reuseErr) {
          console.warn('Failed to verify existing order with Razorpay, generating new order:', reuseErr);
        }
      }
    }

    // 8. Generate unique receipt reference and create new Razorpay Order via official Orders API
    const receiptRef = `rec_${Date.now().toString(36)}_${Math.random().toString(36).substring(2, 6)}`;
    const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${basicAuth}`,
      },
      body: JSON.stringify({
        amount: amountPaise,
        currency: 'INR',
        receipt: receiptRef,
        notes: {
          student_id: student.id,
          student_code: student.student_id || 'N/A',
          student_name: student.full_name,
          course_id: courseData?.id || 'general',
          course_name: courseData?.title || 'Institutional Fee / Subscription',
          initiated_by: profile.email || profile.full_name,
          source: 'IIECM Admin Mobile',
        },
      }),
    });

    if (!razorpayResponse.ok) {
      const errorText = await razorpayResponse.text();
      let errorObj;
      try {
        errorObj = JSON.parse(errorText);
      } catch (_) {
        errorObj = { message: errorText };
      }
      return new Response(
        JSON.stringify({
          error: 'Razorpay Order creation failed',
          details: errorObj,
        }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const orderData = await razorpayResponse.json();

    // 8. Create a pending payment record in public.payments
    const pendingTxnRef = `order_${orderData.id}`;
    const insertPayload = {
      transaction_ref: pendingTxnRef,
      student_id: student.id,
      student_name: student.full_name,
      course_id: courseData?.id || null,
      course_name: courseData?.title || 'Institutional Program',
      amount: amount,
      currency: 'INR',
      payment_method: 'razorpay',
      status: 'pending',
      payment_date: new Date().toISOString(),
      refund_status: 'none',
      notes: notes || 'Online Razorpay checkout initiated',
      raw_provider_payload: {
        razorpay_order_id: orderData.id,
        amount_paise: amountPaise,
        receipt: receiptRef,
        created_at: new Date().toISOString(),
        initiated_by_admin: profile.full_name,
      },
    };

    let paymentRecord: any = null;
    const { data: insertedData, error: insertError } = await adminClient
      .from('payments')
      .insert(insertPayload)
      .select()
      .single();

    if (insertError) {
      console.warn(`Initial database insert failed for order ${orderData.id}, attempting retry:`, insertError.message);
      // Attempt retry once to prevent unnecessary orphaned orders
      const { data: retryData, error: retryError } = await adminClient
        .from('payments')
        .insert(insertPayload)
        .select()
        .single();

      if (retryError || !retryData) {
        // Safe Orphan Handling: Razorpay order exists on gateway but could not be persisted
        console.error(
          `CRITICAL: Orphaned Razorpay order created on gateway (orderId=${orderData.id}, receipt=${receiptRef}) for student ${student.id} (amount=₹${amount}), but database insertion failed after retry: ${retryError?.message || insertError.message}`
        );
        return new Response(
          JSON.stringify({
            error: 'Failed to record pending transaction in database. Please contact administrator.',
            orderId: orderData.id,
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      paymentRecord = retryData;
    } else {
      paymentRecord = insertedData;
    }

    // 9. Return checkout payload to Flutter
    return new Response(
      JSON.stringify({
        success: true,
        paymentId: paymentRecord.id,
        orderId: orderData.id,
        amountPaise: amountPaise,
        amountInr: amount,
        currency: 'INR',
        keyId: razorpayKeyId,
        student: {
          id: student.id,
          code: student.student_id,
          name: student.full_name,
          email: student.email,
          phone: student.phone,
        },
        course: courseData,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Internal Server Error';
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
