export type UserRole = 'super_admin' | 'admin' | 'instructor' | 'student';

export type AccountStatus = 'active' | 'inactive' | 'suspended';

export interface AdminUser {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
  avatarUrl?: string;
  phone?: string;
  lastLoginAt?: string;
  createdAt: string;
}

export type SubscriptionPlan = 'free' | 'basic' | 'premium' | 'enterprise';
export type SubscriptionStatus = 'active' | 'expired' | 'pending' | 'cancelled';

export interface Student {
  id: string;
  studentId: string;
  fullName: string;
  email: string;
  phone: string;
  educationLevel: string;
  qualification: string;
  preferredCategory: string;
  assignedCourseIds: string[];
  subscriptionPlan: SubscriptionPlan;
  subscriptionStatus: SubscriptionStatus;
  subscriptionStart?: string;
  subscriptionExpiry?: string;
  accountStatus: AccountStatus;
  resumeUploaded: boolean;
  careerGuidanceStatus: 'not_started' | 'in_progress' | 'completed';
  enrolledCourseIds: string[];
  createdAt: string;
  city?: string;
  country?: string;
}

export interface Instructor {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  qualifications: string;
  specialization: string;
  experienceYears: number;
  assignedCourseIds: string[];
  accountStatus: AccountStatus;
  bio?: string;
  createdAt: string;
  rating?: number;
  totalStudents?: number;
  totalClasses?: number;
}

export type CourseStatus = 'draft' | 'published' | 'archived';
export type LearningFormat = 'live' | 'recorded' | 'hybrid';

export interface Lesson {
  id: string;
  title: string;
  durationMinutes: number;
  type: 'video' | 'reading' | 'quiz' | 'assignment';
  order: number;
}

export interface Module {
  id: string;
  title: string;
  description?: string;
  lessons: Lesson[];
  order: number;
}

export interface Course {
  id: string;
  title: string;
  description: string;
  category: string;
  thumbnailUrl?: string;
  instructorId?: string;
  durationWeeks: number;
  fee: number;
  learningObjectives: string[];
  prerequisites: string[];
  modules: Module[];
  format: LearningFormat;
  status: CourseStatus;
  enrolledStudentIds: string[];
  createdAt: string;
  publishedAt?: string;
}

export type PaymentStatus = 'pending' | 'verified' | 'rejected' | 'failed' | 'refunded';
export type PaymentMethod = 'razorpay' | 'bank_transfer' | 'upi' | 'card' | 'cash' | 'cheque';

export interface Payment {
  id: string;
  transactionRef: string;
  studentId: string;
  studentName: string;
  courseId?: string;
  courseName?: string;
  subscriptionPlan?: SubscriptionPlan;
  amount: number;
  paymentMethod: PaymentMethod;
  status: PaymentStatus;
  paymentDate: string;
  verifiedBy?: string;
  rejectionReason?: string;
  refundStatus?: 'none' | 'initiated' | 'completed' | 'rejected';
  subscriptionStart?: string;
  subscriptionExpiry?: string;
  notes?: string;
}

export type EnquiryStatus = 'new' | 'contacted' | 'follow_up' | 'converted' | 'closed';
export type EnquirySource = 'website' | 'referral' | 'social_media' | 'walk_in' | 'phone' | 'email';
export type LearningMode = 'online' | 'offline' | 'hybrid';

export interface FollowUpEntry {
  id: string;
  date: string;
  note: string;
  by: string;
  outcome: 'no_response' | 'interested' | 'not_interested' | 'callback_scheduled' | 'converted';
}

export interface Enquiry {
  id: string;
  enquiryId: string;
  studentName: string;
  email: string;
  phone: string;
  educationLevel: string;
  careerInterests: string[];
  preferredService: string;
  budgetMin: number;
  budgetMax: number;
  preferredMode: LearningMode;
  source: EnquirySource;
  assignedCounsellor: string;
  followUpDate: string;
  status: EnquiryStatus;
  notes: string;
  followUpHistory: FollowUpEntry[];
  createdAt: string;
}

export type AssessmentType = 'mcq' | 'assignment' | 'project' | 'quiz';
export type AssessmentStatus = 'draft' | 'scheduled' | 'active' | 'completed';

export interface QuestionOption {
  id: string;
  text: string;
  isCorrect: boolean;
}

export interface Question {
  id: string;
  questionText: string;
  options: QuestionOption[];
  marks: number;
  type: 'mcq' | 'true_false' | 'short_answer';
}

export interface AssessmentCategory {
  id: string;
  name: string;
  description: string;
  questionCount: number;
}

export interface Assessment {
  id: string;
  title: string;
  description: string;
  categoryId: string;
  type: AssessmentType;
  totalMarks: number;
  passingMarks: number;
  durationMinutes: number;
  status: AssessmentStatus;
  questionIds: string[];
  assignedStudentIds: string[];
  assignedCourseIds: string[];
  scheduledAt?: string;
  createdBy: string;
  createdAt: string;
}

export interface AssessmentResult {
  id: string;
  assessmentId: string;
  assessmentTitle: string;
  studentId: string;
  studentName: string;
  score: number;
  totalMarks: number;
  percentage: number;
  passed: boolean;
  completedAt: string;
}

export type AppointmentStatus = 'scheduled' | 'completed' | 'cancelled' | 'no_show';

export interface CareerAppointment {
  id: string;
  studentId: string;
  studentName: string;
  counsellor: string;
  type: 'career_guidance' | 'resume_review' | 'mock_interview' | 'action_plan';
  scheduledAt: string;
  status: AppointmentStatus;
  notes?: string;
}

export interface CareerActionPlan {
  id: string;
  studentId: string;
  studentName: string;
  goals: string[];
  milestones: { id: string; title: string; targetDate: string; completed: boolean }[];
  createdAt: string;
}

export type ResourceType = 'pdf' | 'document' | 'video' | 'link' | 'image';
export type ResourceCategory = 'study_material' | 'career' | 'exam_prep' | 'course' | 'government_exam';
export type ResourceVisibility = 'public' | 'enrolled' | 'private';

export interface Resource {
  id: string;
  title: string;
  description: string;
  type: ResourceType;
  category: ResourceCategory;
  fileSize?: string;
  downloadUrl?: string;
  visibility: ResourceVisibility;
  uploadedBy: string;
  createdAt: string;
  downloadCount: number;
}

export type NotificationType = 'student' | 'instructor' | 'course' | 'payment' | 'class' | 'system';
export type NotificationPriority = 'low' | 'medium' | 'high';

export interface AppNotification {
  id: string;
  title: string;
  message: string;
  type: NotificationType;
  priority: NotificationPriority;
  read: boolean;
  createdAt: string;
  actionUrl?: string;
}

export interface ActivityLog {
  id: string;
  adminName: string;
  action: string;
  target: string;
  timestamp: string;
}

export interface LiveClass {
  id: string;
  title: string;
  courseId: string;
  courseName: string;
  instructorId: string;
  instructorName: string;
  scheduledAt: string;
  durationMinutes: number;
  status: 'upcoming' | 'live' | 'completed' | 'cancelled';
  meetingLink?: string;
}

export interface CourseCategory {
  id: string;
  name: string;
  description: string;
  courseCount: number;
  color: string;
}

export interface SubscriptionPlanConfig {
  id: SubscriptionPlan;
  name: string;
  price: number;
  durationMonths: number;
  features: string[];
  isActive: boolean;
}
