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
import type {
  Student, Instructor, Course, Payment, Enquiry, Assessment, AssessmentResult,
  CareerAppointment, CareerActionPlan, Resource, AppNotification, ActivityLog,
  LiveClass, CourseCategory, SubscriptionPlanConfig, Question, AssessmentCategory,
} from '@/types';

class MockStore {
  students: Student[] = [...initialStudents];
  instructors: Instructor[] = [...initialInstructors];
  courses: Course[] = [...initialCourses];
  payments: Payment[] = [...initialPayments];
  enquiries: Enquiry[] = [...initialEnquiries];
  assessments: Assessment[] = [...initialAssessments];
  assessmentResults: AssessmentResult[] = [...initialResults];
  careerAppointments: CareerAppointment[] = [...initialAppointments];
  careerActionPlans: CareerActionPlan[] = [...initialActionPlans];
  resources: Resource[] = [...initialResources];
  notifications: AppNotification[] = [...initialNotifications];
  activityLogs: ActivityLog[] = [...initialActivity];
  liveClasses: LiveClass[] = [...initialLiveClasses];
  courseCategories: CourseCategory[] = [...initialCategories];
  assessmentCategories: AssessmentCategory[] = [...initialAssessmentCategories];
  subscriptionPlans: SubscriptionPlanConfig[] = [...initialPlans];
  questions: Question[] = [...initialQuestions];

  private listeners = new Set<() => void>();
  subscribe(cb: () => void) { this.listeners.add(cb); return () => this.listeners.delete(cb); }
  private notify() { this.listeners.forEach((cb) => cb()); }

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
    this.notify();
  }
}

export const mockStore = new MockStore();
