import type { Student, Course, Instructor, Payment, Enquiry, Assessment, AssessmentResult } from '@/types';

export interface IntegrityCheckResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

/**
 * Validates integrity of mock datasets, catching any duplicate IDs,
 * invalid foreign keys, or broken bidirectional relationships.
 */
export function validateDatasetIntegrity(datasets: {
  students: Student[];
  courses: Course[];
  instructors: Instructor[];
  payments: Payment[];
  enquiries: Enquiry[];
  assessments: Assessment[];
  assessmentResults: AssessmentResult[];
}): IntegrityCheckResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  const { students, courses, instructors, payments, enquiries, assessments, assessmentResults } = datasets;

  // 1. Verify unique IDs per collection
  function checkUniqueIds(items: { id: string }[], collectionName: string) {
    const seen = new Set<string>();
    items.forEach((item, index) => {
      if (!item.id) {
        errors.push(`[${collectionName}] Record at index ${index} is missing an ID.`);
      } else if (seen.has(item.id)) {
        errors.push(`[${collectionName}] Duplicate ID detected: "${item.id}"`);
      } else {
        seen.add(item.id);
      }
    });
  }

  checkUniqueIds(students, 'Students');
  checkUniqueIds(courses, 'Courses');
  checkUniqueIds(instructors, 'Instructors');
  checkUniqueIds(payments, 'Payments');
  checkUniqueIds(enquiries, 'Enquiries');
  checkUniqueIds(assessments, 'Assessments');
  checkUniqueIds(assessmentResults, 'AssessmentResults');

  // 2. Verify business-level uniqueness constraints
  const seenStudentIds = new Set<string>();
  const seenStudentEmails = new Set<string>();
  students.forEach((s) => {
    if (seenStudentIds.has(s.studentId)) {
      errors.push(`[Students] Duplicate studentId detected: "${s.studentId}"`);
    }
    seenStudentIds.add(s.studentId);

    const email = s.email.toLowerCase().trim();
    if (seenStudentEmails.has(email)) {
      errors.push(`[Students] Duplicate email detected: "${email}"`);
    }
    seenStudentEmails.add(email);
  });

  const seenTxnRefs = new Set<string>();
  payments.forEach((p) => {
    if (seenTxnRefs.has(p.transactionRef)) {
      errors.push(`[Payments] Duplicate transactionRef detected: "${p.transactionRef}"`);
    }
    seenTxnRefs.add(p.transactionRef);
  });

  const seenEnquiryIds = new Set<string>();
  enquiries.forEach((e) => {
    if (seenEnquiryIds.has(e.enquiryId)) {
      errors.push(`[Enquiries] Duplicate enquiryId detected: "${e.enquiryId}"`);
    }
    seenEnquiryIds.add(e.enquiryId);
  });

  // 3. Bidirectional Student <-> Course Enrollment consistency
  const studentMap = new Map(students.map((s) => [s.id, s]));
  const courseMap = new Map(courses.map((c) => [c.id, c]));

  students.forEach((s) => {
    s.enrolledCourseIds.forEach((cid) => {
      const course = courseMap.get(cid);
      if (!course) {
        errors.push(`[Students] Student ${s.fullName} (${s.id}) references non-existent course "${cid}".`);
      } else if (!course.enrolledStudentIds.includes(s.id)) {
        errors.push(`[Enrollment Inconsistency] Student ${s.fullName} is enrolled in course "${course.title}", but the course does not list the student in enrolledStudentIds.`);
      }
    });
  });

  courses.forEach((c) => {
    c.enrolledStudentIds.forEach((sid) => {
      const student = studentMap.get(sid);
      if (!student) {
        errors.push(`[Courses] Course ${c.title} (${c.id}) references non-existent student "${sid}".`);
      } else if (!student.enrolledCourseIds.includes(c.id)) {
        errors.push(`[Enrollment Inconsistency] Course "${c.title}" lists student ${student.fullName}, but the student's enrolledCourseIds does not include this course.`);
      }
    });
  });

  // 4. Instructor <-> Course consistency
  const instructorMap = new Map(instructors.map((i) => [i.id, i]));
  courses.forEach((c) => {
    if (c.instructorId) {
      const instructor = instructorMap.get(c.instructorId);
      if (!instructor) {
        errors.push(`[Courses] Course "${c.title}" references non-existent instructorId "${c.instructorId}".`);
      } else if (!instructor.assignedCourseIds.includes(c.id)) {
        warnings.push(`[Instructor Inconsistency] Course "${c.title}" assigned to instructor ${instructor.fullName}, but instructor.assignedCourseIds does not list it.`);
      }
    }
  });

  // 5. Payments referential integrity
  payments.forEach((p) => {
    if (!studentMap.has(p.studentId)) {
      errors.push(`[Payments] Payment "${p.transactionRef}" references non-existent studentId "${p.studentId}".`);
    }
    if (p.courseId && !courseMap.has(p.courseId)) {
      errors.push(`[Payments] Payment "${p.transactionRef}" references non-existent courseId "${p.courseId}".`);
    }
  });

  // 6. Assessments referential integrity
  assessments.forEach((a) => {
    a.assignedCourseIds.forEach((cid) => {
      if (!courseMap.has(cid)) {
        errors.push(`[Assessments] Assessment "${a.title}" references non-existent courseId "${cid}".`);
      }
    });
  });

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Checks if a proposed new student would collide with an existing student by email.
 */
export function isDuplicateStudentEmail(email: string, existingStudents: Student[], excludeId?: string): boolean {
  const normalized = email.trim().toLowerCase();
  return existingStudents.some((s) => s.id !== excludeId && s.email.trim().toLowerCase() === normalized);
}

/**
 * Checks if an enquiry with the same email already exists.
 */
export function isDuplicateEnquiryEmail(email: string, existingEnquiries: Enquiry[], excludeId?: string): boolean {
  const normalized = email.trim().toLowerCase();
  return existingEnquiries.some((e) => e.id !== excludeId && e.email.trim().toLowerCase() === normalized);
}

