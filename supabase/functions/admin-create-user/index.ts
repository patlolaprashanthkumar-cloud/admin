// Supabase Edge Function: admin-create-user
// Description: Securely provisions a new user with verified role and associated student/instructor profile

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface CreateUserPayload {
  email: string;
  password?: string;
  fullName: string;
  role: 'student' | 'instructor' | 'admin';
  phone?: string;
  // Specific student or instructor metadata
  studentId?: string;
  educationLevel?: string;
  qualification?: string;
  preferredCategory?: string;
  specialization?: string;
  experienceYears?: number;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

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

    // Client for checking caller authority
    const callerClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY') ?? serviceRoleKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user: callerUser }, error: callerAuthError } = await callerClient.auth.getUser();
    if (callerAuthError || !callerUser) {
      return new Response(JSON.stringify({ error: 'Unauthorized: Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Admin Client with Service Role for privileged operations
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Verify caller role in public.profiles
    const { data: callerProfile, error: profileError } = await adminClient
      .from('profiles')
      .select('role')
      .eq('id', callerUser.id)
      .single();

    if (profileError || !callerProfile || !['super_admin', 'admin'].includes(callerProfile.role)) {
      return new Response(JSON.stringify({ error: 'Forbidden: Admin access required' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const payload: CreateUserPayload = await req.json();

    // Input validation
    if (!payload.email || !payload.email.includes('@') || !payload.fullName) {
      return new Response(JSON.stringify({ error: 'Valid email and fullName are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Only super_admin can create another admin
    if (payload.role === 'admin' && callerProfile.role !== 'super_admin') {
      return new Response(JSON.stringify({ error: 'Only Super Admins can create administrative accounts' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Default password generation if not provided
    const tempPassword = payload.password || `IIECM_${crypto.randomUUID().slice(0, 8)}!`;

    // 1. Create Auth user via Admin API
    const { data: authData, error: createError } = await adminClient.auth.admin.createUser({
      email: payload.email.trim().toLowerCase(),
      password: tempPassword,
      email_confirm: true,
      user_metadata: {
        full_name: payload.fullName.trim(),
        role: payload.role,
        phone: payload.phone || null,
      },
    });

    if (createError || !authData.user) {
      return new Response(JSON.stringify({ error: createError?.message || 'Failed to create user' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const newUserId = authData.user.id;

    // 2. Ensure profile exists and role is exact
    await adminClient
      .from('profiles')
      .upsert({
        id: newUserId,
        email: payload.email.trim().toLowerCase(),
        full_name: payload.fullName.trim(),
        role: payload.role,
        phone: payload.phone || null,
        updated_at: new Date().toISOString(),
      });

    // 3. Create associated Student or Instructor record
    if (payload.role === 'student') {
      const generatedStudentId = payload.studentId || `IIECM${new Date().getFullYear()}${Math.floor(10000 + Math.random() * 90000)}`;
      const { error: studentError } = await adminClient.from('students').insert({
        profile_id: newUserId,
        student_id: generatedStudentId,
        full_name: payload.fullName.trim(),
        email: payload.email.trim().toLowerCase(),
        phone: payload.phone || '+91 00000 00000',
        education_level: payload.educationLevel || 'Not specified',
        qualification: payload.qualification || 'N/A',
        preferred_category: payload.preferredCategory || 'General',
        account_status: 'active',
        subscription_plan: 'basic',
        subscription_status: 'pending',
      });

      if (studentError) {
        console.error('Error creating student entry:', studentError);
      }
    } else if (payload.role === 'instructor') {
      const { error: instructorError } = await adminClient.from('instructors').insert({
        profile_id: newUserId,
        full_name: payload.fullName.trim(),
        email: payload.email.trim().toLowerCase(),
        phone: payload.phone || '+91 00000 00000',
        qualifications: payload.qualification || 'N/A',
        specialization: payload.specialization || 'General',
        experience_years: payload.experienceYears || 0,
        account_status: 'active',
      });

      if (instructorError) {
        console.error('Error creating instructor entry:', instructorError);
      }
    }

    // 4. Log the admin action
    await adminClient.from('activity_logs').insert({
      admin_id: callerUser.id,
      admin_name: callerUser.user_metadata?.full_name || callerUser.email || 'Admin',
      action: 'Created user account',
      target: `${payload.fullName} (${payload.email}) as ${payload.role}`,
      timestamp: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({
        success: true,
        userId: newUserId,
        email: payload.email,
        role: payload.role,
        generatedPassword: payload.password ? undefined : tempPassword,
      }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown server error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

