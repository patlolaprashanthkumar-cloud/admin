// Database Types for Supabase schema
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type UserRole = 'super_admin' | 'admin' | 'instructor' | 'student';
export type AccountStatus = 'active' | 'inactive' | 'suspended';
export type SubscriptionPlan = 'free' | 'basic' | 'premium' | 'enterprise';
export type SubscriptionStatus = 'active' | 'expired' | 'pending' | 'cancelled';
export type CourseStatus = 'draft' | 'published' | 'archived';
export type LearningFormat = 'live' | 'recorded' | 'hybrid';
export type PaymentStatus = 'pending' | 'verified' | 'rejected' | 'failed' | 'refunded';
export type PaymentMethod = 'razorpay' | 'bank_transfer' | 'upi' | 'card' | 'cash' | 'cheque';
export type EnquiryStatus = 'new' | 'contacted' | 'follow_up' | 'converted' | 'closed';

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          full_name: string;
          role: UserRole;
          phone: string | null;
          avatar_url: string | null;
          last_login_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          full_name: string;
          role?: UserRole;
          phone?: string | null;
          avatar_url?: string | null;
          last_login_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          email?: string;
          full_name?: string;
          role?: UserRole;
          phone?: string | null;
          avatar_url?: string | null;
          last_login_at?: string | null;
          updated_at?: string;
        };
      };
      students: {
        Row: {
          id: string;
          profile_id: string | null;
          student_id: string;
          full_name: string;
          email: string;
          phone: string;
          education_level: string;
          qualification: string;
          preferred_category: string;
          subscription_plan: SubscriptionPlan;
          subscription_status: SubscriptionStatus;
          subscription_start: string | null;
          subscription_expiry: string | null;
          account_status: AccountStatus;
          resume_uploaded: boolean;
          career_guidance_status: 'not_started' | 'in_progress' | 'completed';
          city: string | null;
          country: string;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['students']['Row'], 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['students']['Insert']>;
      };
      instructors: {
        Row: {
          id: string;
          profile_id: string | null;
          full_name: string;
          email: string;
          phone: string;
          qualifications: string;
          specialization: string;
          experience_years: number;
          account_status: AccountStatus;
          bio: string | null;
          rating: number | null;
          total_students: number;
          total_classes: number;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['instructors']['Row'], 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['instructors']['Insert']>;
      };
      courses: {
        Row: {
          id: string;
          title: string;
          description: string;
          category_id: string | null;
          category_name: string;
          thumbnail_url: string | null;
          instructor_id: string | null;
          duration_weeks: number;
          fee: number;
          learning_objectives: string[];
          prerequisites: string[];
          format: LearningFormat;
          status: CourseStatus;
          published_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['courses']['Row'], 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['courses']['Insert']>;
      };
      course_modules: {
        Row: {
          id: string;
          course_id: string;
          title: string;
          description: string | null;
          order_index: number;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['course_modules']['Row'], 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['course_modules']['Insert']>;
      };
      course_lessons: {
        Row: {
          id: string;
          module_id: string;
          title: string;
          duration_minutes: number;
          type: 'video' | 'reading' | 'quiz' | 'assignment';
          order_index: number;
          content_url: string | null;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['course_lessons']['Row'], 'id' | 'created_at'> & {
          id?: string;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['course_lessons']['Insert']>;
      };
      course_enrollments: {
        Row: {
          id: string;
          student_id: string;
          course_id: string;
          status: string;
          enrolled_at: string;
          completed_at: string | null;
        };
        Insert: Omit<Database['public']['Tables']['course_enrollments']['Row'], 'id' | 'enrolled_at'> & {
          id?: string;
          enrolled_at?: string;
        };
        Update: Partial<Database['public']['Tables']['course_enrollments']['Insert']>;
      };
      payments: {
        Row: {
          id: string;
          transaction_ref: string;
          student_id: string;
          student_name: string;
          course_id: string | null;
          course_name: string | null;
          subscription_plan: SubscriptionPlan | null;
          amount: number;
          currency: string;
          payment_method: PaymentMethod;
          status: PaymentStatus;
          payment_date: string;
          verified_by: string | null;
          rejection_reason: string | null;
          refund_status: 'none' | 'initiated' | 'completed' | 'rejected';
          subscription_start: string | null;
          subscription_expiry: string | null;
          notes: string | null;
          raw_provider_payload: Json | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['payments']['Row'], 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['payments']['Insert']>;
      };
      enquiries: {
        Row: {
          id: string;
          enquiry_id: string;
          student_name: string;
          email: string;
          phone: string;
          education_level: string;
          career_interests: string[];
          preferred_service: string;
          budget_min: number;
          budget_max: number;
          preferred_mode: 'online' | 'offline' | 'hybrid';
          source: string;
          assigned_counsellor: string;
          follow_up_date: string | null;
          status: EnquiryStatus;
          notes: string;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['enquiries']['Row'], 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['enquiries']['Insert']>;
      };
      activity_logs: {
        Row: {
          id: string;
          admin_id: string | null;
          admin_name: string;
          action: string;
          target: string;
          ip_address: string | null;
          metadata: Json;
          timestamp: string;
        };
        Insert: Omit<Database['public']['Tables']['activity_logs']['Row'], 'id' | 'timestamp'> & {
          id?: string;
          timestamp?: string;
        };
        Update: Partial<Database['public']['Tables']['activity_logs']['Insert']>;
      };
    };
  };
}

