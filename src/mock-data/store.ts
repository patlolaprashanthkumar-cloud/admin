import {
  students as initialStudents, instructors as initialInstructors, courses as initialCourses,
  payments as initialPayments, enquiries as initialEnquiries, assessments as initialAssessments,
  assessmentResults as initialResults, careerAppointments as initialAppointments,
  careerActionPlans as initialActionPlans, resources as initialResources,
  notifications as initialNotifications, activityLogs as initialActivity,
  liveClasses as initialLiveClasses, courseCategories as initialCategories,
  subscriptionPlans as initialPlans, questions as initialQuestions,
  assessmentCategories as initialAssessmentCategories,
} from '@/mock-data';
import type { Student, Instructor, Course, Payment, Enquiry, Assessment, AssessmentResult, CareerAppointment, CareerActionPlan, Resource, AppNotification, ActivityLog, LiveClass, CourseCategory, SubscriptionPlanConfig, Question, AssessmentCategory } from '@/types';
import { isDemoMode } from '@/services/supabase/auth';

class MockStore {
  students: Student[] = [];
  instructors: Instructor[] = [];
  courses: Course[] = [];
  payments: Payment[] = [];
  enquiries: Enquiry[] = [];
  assessments: Assessment[] = [];
  assessmentResults: AssessmentResult[] = [];
  careerAppointments: CareerAppointment[] = [];
  careerActionPlans: CareerActionPlan[] = [];
  resources: Resource[] = [];
  notifications: AppNotification[] = [];
  activityLogs: ActivityLog[] = [];
  liveClasses: LiveClass[] = [];
  courseCategories: CourseCategory[] = [];
  assessmentCategories: AssessmentCategory[] = [];
  subscriptionPlans: SubscriptionPlanConfig[] = [];
  questions: Question[] = [];

  constructor() {
    if (isDemoMode()) {
      this.students = [...initialStudents];
      this.instructors = [...initialInstructors];
      this.courses = [...initialCourses];
      this.payments = [...initialPayments];
      this.enquiries = [...initialEnquiries];
      this.assessments = [...initialAssessments];
      this.assessmentResults = [...initialResults];
      this.careerAppointments = [...initialAppointments];
      this.careerActionPlans = [...initialActionPlans];
      this.resources = [...initialResources];
      this.notifications = [...initialNotifications];
      this.activityLogs = [...initialActivity];
      this.liveClasses = [...initialLiveClasses];
      this.courseCategories = [...initialCategories];
      this.assessmentCategories = [...initialAssessmentCategories];
      this.subscriptionPlans = [...initialPlans];
      this.questions = [...initialQuestions];
    }
  }

  private listeners = new Set<() => void>();
  subscribe(cb: () => void) { this.listeners.add(cb); return () => this.listeners.delete(cb); }
  private notify() { this.listeners.forEach((cb) => cb()); }

// Category management
// Add a new category (active by default)
addCategory(cat: CourseCategory | Omit<CourseCategory, 'id'>) {
  const id = ('id' in cat && cat.id) ? cat.id : 'cat-' + Date.now();
  const newCat: CourseCategory = { courseCount: 0, isActive: true, ...cat, id };
  this.courseCategories.unshift(newCat);
  this.notify();
}

// Update existing category fields
updateCategory(id: string, patch: Partial<Omit<CourseCategory, 'id'>>) {
  this.courseCategories = this.courseCategories.map((c) => c.id === id ? { ...c, ...patch } : c);
  this.notify();
}

// Delete a category
deleteCategory(id: string) {
  this.courseCategories = this.courseCategories.filter((c) => c.id !== id);
  this.notify();
}

// Toggle active status
toggleCategoryActive(id: string, active?: boolean) {
  this.courseCategories = this.courseCategories.map((c) => c.id === id ? { ...c, isActive: active !== undefined ? active : !c.isActive } : c);
  this.notify();
}


  addStudent(s: Student) { this.students.unshift(s); this.notify(); }
  updateStudent(id: string, patch: Partial<Student>) {
    this.students = this.students.map((s) => (s.id === id ? { ...s, ...patch } : s));
    this.notify();
  }
  deleteStudent(id: string) {
    this.students = this.students.filter((s) => s.id !== id);
    this.notify();
  }

  addInstructor(i: Instructor) { this.instructors.unshift(i); this.notify(); }
  updateInstructor(id: string, patch: Partial<Instructor>) {
    this.instructors = this.instructors.map((i) => (i.id === id ? { ...i, ...patch } : i));
    this.notify();
  }

  addCourse(c: Course) { this.courses.unshift(c); this.notify(); }
  updateCourse(id: string, patch: Partial<Course>) {
    this.courses = this.courses.map((c) => (c.id === id ? { ...c, ...patch } : c));
    this.notify();
  }
  deleteCourse(id: string) {
    this.courses = this.courses.filter((c) => c.id !== id);
    this.notify();
  }

  addPayment(p: Payment) { this.payments.unshift(p); this.notify(); }
  updatePayment(id: string, patch: Partial<Payment>) {
    this.payments = this.payments.map((p) => (p.id === id ? { ...p, ...patch } : p));
    this.notify();
  }

  addEnquiry(e: Enquiry) { this.enquiries.unshift(e); this.notify(); }
  updateEnquiry(id: string, patch: Partial<Enquiry>) {
    this.enquiries = this.enquiries.map((e) => (e.id === id ? { ...e, ...patch } : e));
    this.notify();
  }

  addAssessment(a: Assessment) { this.assessments.unshift(a); this.notify(); }
  updateAssessment(id: string, patch: Partial<Assessment>) {
    this.assessments = this.assessments.map((a) => (a.id === id ? { ...a, ...patch } : a));
    this.notify();
  }

  addResource(r: Resource) { this.resources.unshift(r); this.notify(); }
  updateResource(id: string, patch: Partial<Resource>) {
    this.resources = this.resources.map((r) => (r.id === id ? { ...r, ...patch } : r));
    this.notify();
  }
  deleteResource(id: string) {
    this.resources = this.resources.filter((r) => r.id !== id);
    this.notify();
  }

  markNotificationRead(id: string) {
    this.notifications = this.notifications.map((n) => (n.id === id ? { ...n, read: true } : n));
    this.notify();
  }
  markAllNotificationsRead() {
    this.notifications = this.notifications.map((n) => ({ ...n, read: true }));
    this.notify();
  }

  addActivity(log: ActivityLog) {
    this.activityLogs.unshift(log);
    this.notify();
  }

  reset() {
    // Reset to demo data only when demo mode is active; otherwise clear store.
    if (isDemoMode()) {
      this.students = [...initialStudents];
      this.instructors = [...initialInstructors];
      this.courses = [...initialCourses];
      this.payments = [...initialPayments];
      this.enquiries = [...initialEnquiries];
      this.assessments = [...initialAssessments];
      this.assessmentResults = [...initialResults];
      this.careerAppointments = [...initialAppointments];
      this.careerActionPlans = [...initialActionPlans];
      this.resources = [...initialResources];
      this.notifications = [...initialNotifications];
      this.activityLogs = [...initialActivity];
      this.liveClasses = [...initialLiveClasses];
    } else {
      this.students = [];
      this.instructors = [];
      this.courses = [];
      this.payments = [];
      this.enquiries = [];
      this.assessments = [];
      this.assessmentResults = [];
      this.careerAppointments = [];
      this.careerActionPlans = [];
      this.resources = [];
      this.notifications = [];
      this.activityLogs = [];
      this.liveClasses = [];
    }
    this.notify();
  }
}

export const mockStore = new MockStore();
