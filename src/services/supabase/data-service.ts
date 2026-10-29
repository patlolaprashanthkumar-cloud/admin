// Supabase Database Service Layer
// Direct PostgreSQL query and mutation handlers for production use

import { supabase, isSupabaseConfigured } from './client';
import type { Student, Course, Instructor, Payment, Enquiry, Assessment } from '@/types';

export class SupabaseDataService {
  static isAvailable(): boolean {
    return isSupabaseConfigured && supabase !== null;
  }

  // --- Students ---
  static async getStudents(): Promise<{ data: Student[]; error?: string }> {
    if (!supabase) return { data: [], error: 'Supabase client not initialized' };

    const { data, error } = await supabase
      .from('students')
      .select('*, course_enrollments(course_id)')
      .order('created_at', { ascending: false });

    if (error) return { data: [], error: error.message };

    const students: Student[] = (data || []).map((row: any) => ({
      id: row.id,
      studentId: row.student_id,
      fullName: row.full_name,
      email: row.email,
      phone: row.phone,
      educationLevel: row.education_level,
      qualification: row.qualification,
      preferredCategory: row.preferred_category,
      subscriptionPlan: row.subscription_plan,
      subscriptionStatus: row.subscription_status,
      subscriptionStart: row.subscription_start,
      subscriptionExpiry: row.subscription_expiry,
      accountStatus: row.account_status,
      resumeUploaded: row.resume_uploaded,
      careerGuidanceStatus: row.career_guidance_status,
      enrolledCourseIds: (row.course_enrollments || []).map((e: any) => e.course_id),
      city: row.city,
      country: row.country,
      createdAt: row.created_at,
    }));

    return { data: students };
  }

  static async createStudent(student: Omit<Student, 'id'>): Promise<{ data?: Student; error?: string }> {
    if (!supabase) return { error: 'Supabase client not initialized' };

    const { data, error } = (await supabase
      .from('students')
      .insert({
        student_id: student.studentId,
        full_name: student.fullName,
        email: student.email,
        phone: student.phone,
        education_level: student.educationLevel,
        qualification: student.qualification,
        preferred_category: student.preferredCategory,
        subscription_plan: student.subscriptionPlan,
        subscription_status: student.subscriptionStatus,
        account_status: student.accountStatus,
        city: student.city || null,
        country: student.country,
      } as any)
      .select()
      .single()) as { data: any; error: any };

    if (error) return { error: error.message };

    // Enroll in specified courses
    if (student.enrolledCourseIds && student.enrolledCourseIds.length > 0) {
      const enrollments = student.enrolledCourseIds.map((cid) => ({
        student_id: data.id,
        course_id: cid,
      }));
      await supabase.from('course_enrollments').insert(enrollments as any);
    }

    return {
      data: {
        ...student,
        id: data.id,
        enrolledCourseIds: student.enrolledCourseIds,
        createdAt: data.created_at,
      },
    };
  }

  // --- Courses ---
  static async getCourses(): Promise<{ data: Course[]; error?: string }> {
    if (!supabase) return { data: [], error: 'Supabase client not initialized' };

    const { data, error } = await supabase
      .from('courses')
      .select('*, course_modules(*, course_lessons(*)), course_enrollments(student_id)')
      .order('created_at', { ascending: false });

    if (error) return { data: [], error: error.message };

    const courses: Course[] = (data || []).map((row: any) => ({
      id: row.id,
      title: row.title,
      description: row.description,
      category: row.category_name,
      thumbnailUrl: row.thumbnail_url || undefined,
      instructorId: row.instructor_id || undefined,
      durationWeeks: row.duration_weeks,
      fee: Number(row.fee),
      learningObjectives: row.learning_objectives || [],
      prerequisites: row.prerequisites || [],
      format: row.format,
      status: row.status,
      publishedAt: row.published_at || undefined,
      createdAt: row.created_at,
      enrolledStudentIds: (row.course_enrollments || []).map((e: any) => e.student_id),
      modules: (row.course_modules || []).map((m: any) => ({
        id: m.id,
        title: m.title,
        description: m.description,
        order: m.order_index,
        lessons: (m.course_lessons || []).map((l: any) => ({
          id: l.id,
          title: l.title,
          durationMinutes: l.duration_minutes,
          type: l.type,
          order: l.order_index,
        })),
      })),
    }));

    return { data: courses };
  }

  // --- Payments ---
  static async getPayments(): Promise<{ data: Payment[]; error?: string }> {
    if (!supabase) return { data: [], error: 'Supabase client not initialized' };

    const { data, error } = await supabase
      .from('payments')
      .select('*')
      .order('payment_date', { ascending: false });

    if (error) return { data: [], error: error.message };

    const payments: Payment[] = (data || []).map((row: any) => ({
      id: row.id,
      transactionRef: row.transaction_ref,
      studentId: row.student_id,
      studentName: row.student_name,
      courseId: row.course_id || undefined,
      courseName: row.course_name || undefined,
      subscriptionPlan: row.subscription_plan || undefined,
      amount: Number(row.amount),
      paymentMethod: row.payment_method,
      status: row.status,
      paymentDate: row.payment_date,
      verifiedBy: row.verified_by || undefined,
      rejectionReason: row.rejection_reason || undefined,
      refundStatus: row.refund_status,
      subscriptionStart: row.subscription_start || undefined,
      subscriptionExpiry: row.subscription_expiry || undefined,
      notes: row.notes || undefined,
    }));

    return { data: payments };
  }
}
