import type {
  Student, Instructor, Course, Payment, Enquiry, AssessmentCategory,
  Assessment, AssessmentResult, CareerAppointment, CareerActionPlan,
  Resource, AppNotification, ActivityLog, LiveClass, CourseCategory,
  SubscriptionPlanConfig, AdminUser, Question,
} from '@/types';

export const demoAdmin: AdminUser = {
  id: 'admin-001',
  email: 'admin@iiecm.org',
  fullName: 'Dr. Priya Sharma',
  role: 'super_admin',
  phone: '+91 98765 43210',
  createdAt: '2024-01-15T09:00:00Z',
  lastLoginAt: new Date().toISOString(),
};

export const courseCategories: CourseCategory[] = [
  { id: 'cat-1', name: 'E-Commerce Management', description: 'Digital commerce operations and strategy', courseCount: 2, color: '#335598' },
  { id: 'cat-2', name: 'Digital Marketing', description: 'SEO, SEM, social media, and content marketing', courseCount: 2, color: '#0d9488' },
  { id: 'cat-3', name: 'Supply Chain', description: 'Logistics, procurement, and inventory', courseCount: 1, color: '#f59e0b' },
  { id: 'cat-4', name: 'Business Analytics', description: 'Data-driven decision making', courseCount: 1, color: '#6366f1' },
  { id: 'cat-5', name: 'Entrepreneurship', description: 'Startup building and venture management', courseCount: 1, color: '#0891b2' },
  { id: 'cat-6', name: 'Government Exam Prep', description: 'UPSC, SSC, and banking exam preparation', courseCount: 0, color: '#b45309' },
];

export const subscriptionPlans: SubscriptionPlanConfig[] = [
  { id: 'free', name: 'Free Access', price: 0, durationMonths: 0, features: ['Browse course catalog', 'Preview lessons'], isActive: true },
  { id: 'basic', name: 'Basic Plan', price: 4999, durationMonths: 6, features: ['1 course access', 'Recorded sessions', 'Community support'], isActive: true },
  { id: 'premium', name: 'Premium Plan', price: 9999, durationMonths: 12, features: ['3 course access', 'Live + recorded sessions', 'Career guidance', 'Assessment access'], isActive: true },
  { id: 'enterprise', name: 'Enterprise Plan', price: 24999, durationMonths: 12, features: ['Unlimited courses', 'Dedicated counsellor', 'Resume review', 'Mock interviews', 'Priority support'], isActive: true },
];

export const instructors: Instructor[] = [
  { id: 'ins-1', fullName: 'Prof. Rajesh Kumar', email: 'rajesh.kumar@iiecm.org', phone: '+91 98200 11223', qualifications: 'PhD in E-Commerce, MBA IIM-A', specialization: 'E-Commerce Strategy', experienceYears: 15, assignedCourseIds: ['crs-1', 'crs-5'], accountStatus: 'active', bio: 'Former Amazon India strategy lead with 15 years of academic and industry experience.', createdAt: '2024-02-01T09:00:00Z', rating: 4.8, totalStudents: 340, totalClasses: 180 },
  { id: 'ins-2', fullName: 'Dr. Anjali Mehta', email: 'anjali.mehta@iiecm.org', phone: '+91 98201 44556', qualifications: 'PhD Marketing, MSc Analytics', specialization: 'Digital Marketing & Analytics', experienceYears: 12, assignedCourseIds: ['crs-2', 'crs-6'], accountStatus: 'active', bio: 'Digital marketing consultant for 50+ brands across India and Southeast Asia.', createdAt: '2024-02-05T09:00:00Z', rating: 4.9, totalStudents: 520, totalClasses: 240 },
  { id: 'ins-3', fullName: 'Mr. Vikram Singh', email: 'vikram.singh@iiecm.org', phone: '+91 98202 77889', qualifications: 'MBA Operations, B.Tech Mechanical', specialization: 'Supply Chain Management', experienceYears: 18, assignedCourseIds: ['crs-3'], accountStatus: 'active', bio: 'Supply chain director with experience at Flipkart and BigBasket.', createdAt: '2024-02-10T09:00:00Z', rating: 4.6, totalStudents: 210, totalClasses: 95 },
  { id: 'ins-4', fullName: 'Ms. Kavya Reddy', email: 'kavya.reddy@iiecm.org', phone: '+91 98203 22001', qualifications: 'MSc Data Science, B.Tech CSE', specialization: 'Business Analytics', experienceYears: 8, assignedCourseIds: ['crs-4'], accountStatus: 'active', bio: 'Data science lead at a fintech startup, passionate about teaching.', createdAt: '2024-03-01T09:00:00Z', rating: 4.7, totalStudents: 180, totalClasses: 72 },
  { id: 'ins-5', fullName: 'Mr. Arjun Nair', email: 'arjun.nair@iiecm.org', phone: '+91 98204 66007', qualifications: 'MBA Entrepreneurship, B.Com', specialization: 'Startup Building & Venture Capital', experienceYears: 10, assignedCourseIds: ['crs-7'], accountStatus: 'inactive', bio: 'Serial entrepreneur, two successful exits in ed-tech and health-tech.', createdAt: '2024-03-15T09:00:00Z', rating: 4.5, totalStudents: 95, totalClasses: 48 },
];

export const courses: Course[] = [
  {
    id: 'crs-1', title: 'E-Commerce Operations Masterclass', description: 'Comprehensive course covering e-commerce platform management, marketplace operations, seller analytics, and growth strategies.', category: 'E-Commerce Management', thumbnailUrl: '', instructorId: 'ins-1', durationWeeks: 12, fee: 12999,
    learningObjectives: ['Build and scale an e-commerce store', 'Master marketplace seller operations', 'Optimize product listings for conversion', 'Analyze seller analytics dashboards'],
    prerequisites: ['Basic computer literacy', 'Understanding of retail concepts'],
    modules: [
      { id: 'mod-1-1', title: 'Foundations of E-Commerce', order: 1, lessons: [
        { id: 'les-1-1', title: 'Introduction to E-Commerce', durationMinutes: 45, type: 'video', order: 1 },
        { id: 'les-1-2', title: 'E-Commerce Business Models', durationMinutes: 38, type: 'video', order: 2 },
        { id: 'les-1-3', title: 'Marketplace vs D2C', durationMinutes: 30, type: 'reading', order: 3 },
      ]},
      { id: 'mod-1-2', title: 'Platform Setup & Catalog Management', order: 2, lessons: [
        { id: 'les-2-1', title: 'Setting up Seller Central', durationMinutes: 50, type: 'video', order: 1 },
        { id: 'les-2-2', title: 'Product Listing Best Practices', durationMinutes: 42, type: 'video', order: 2 },
        { id: 'les-2-3', title: 'Catalog Optimization Quiz', durationMinutes: 20, type: 'quiz', order: 3 },
      ]},
      { id: 'mod-1-3', title: 'Growth & Analytics', order: 3, lessons: [
        { id: 'les-3-1', title: 'Sponsored Ads & PPC', durationMinutes: 55, type: 'video', order: 1 },
        { id: 'les-3-2', title: 'Reading Analytics Dashboards', durationMinutes: 40, type: 'video', order: 2 },
        { id: 'les-3-3', title: 'Growth Strategy Assignment', durationMinutes: 0, type: 'assignment', order: 3 },
      ]},
    ],
    format: 'hybrid', status: 'published', enrolledStudentIds: ['stu-1', 'stu-2', 'stu-3', 'stu-5', 'stu-8'],
    createdAt: '2024-03-01T09:00:00Z', publishedAt: '2024-03-15T09:00:00Z',
  },
  {
    id: 'crs-2', title: 'Digital Marketing Certification', description: 'Master SEO, SEM, social media marketing, content strategy, and marketing analytics in this hands-on certification program.', category: 'Digital Marketing', instructorId: 'ins-2', durationWeeks: 16, fee: 15999,
    learningObjectives: ['Run full-funnel digital campaigns', 'Perform technical and on-page SEO', 'Build content marketing strategies', 'Use Google Analytics and Ads effectively'],
    prerequisites: ['Basic marketing knowledge', 'Familiarity with social media platforms'],
    modules: [
      { id: 'mod-2-1', title: 'SEO Fundamentals', order: 1, lessons: [
        { id: 'les-dm-1', title: 'How Search Engines Work', durationMinutes: 35, type: 'video', order: 1 },
        { id: 'les-dm-2', title: 'Keyword Research', durationMinutes: 48, type: 'video', order: 2 },
      ]},
      { id: 'mod-2-2', title: 'Paid Advertising', order: 2, lessons: [
        { id: 'les-dm-3', title: 'Google Ads Setup', durationMinutes: 52, type: 'video', order: 1 },
        { id: 'les-dm-4', title: 'Facebook & Instagram Ads', durationMinutes: 46, type: 'video', order: 2 },
      ]},
    ],
    format: 'hybrid', status: 'published', enrolledStudentIds: ['stu-1', 'stu-3', 'stu-4', 'stu-6', 'stu-7', 'stu-9'],
    createdAt: '2024-03-05T09:00:00Z', publishedAt: '2024-03-20T09:00:00Z',
  },
  {
    id: 'crs-3', title: 'Supply Chain & Logistics Management', description: 'End-to-end supply chain management covering procurement, inventory, warehousing, logistics, and distribution networks.', category: 'Supply Chain', instructorId: 'ins-3', durationWeeks: 10, fee: 10999,
    learningObjectives: ['Design efficient supply chain networks', 'Optimize inventory levels', 'Manage vendor relationships', 'Apply lean logistics principles'],
    prerequisites: ['Basic business understanding'],
    modules: [
      { id: 'mod-3-1', title: 'Supply Chain Basics', order: 1, lessons: [
        { id: 'les-sc-1', title: 'What is Supply Chain?', durationMinutes: 30, type: 'video', order: 1 },
        { id: 'les-sc-2', title: 'Procurement Process', durationMinutes: 42, type: 'video', order: 2 },
      ]},
    ],
    format: 'recorded', status: 'published', enrolledStudentIds: ['stu-2', 'stu-5', 'stu-10'],
    createdAt: '2024-03-10T09:00:00Z', publishedAt: '2024-03-25T09:00:00Z',
  },
  {
    id: 'crs-4', title: 'Business Analytics with Python', description: 'Learn data analysis, visualization, and predictive modeling using Python for real-world business decisions.', category: 'Business Analytics', instructorId: 'ins-4', durationWeeks: 14, fee: 18999,
    learningObjectives: ['Perform exploratory data analysis', 'Build predictive models', 'Create business dashboards', 'Apply statistical inference'],
    prerequisites: ['Basic Python programming', 'High school mathematics'],
    modules: [
      { id: 'mod-4-1', title: 'Data Analysis Foundations', order: 1, lessons: [
        { id: 'les-ba-1', title: 'Introduction to Pandas', durationMinutes: 40, type: 'video', order: 1 },
        { id: 'les-ba-2', title: 'Data Cleaning Techniques', durationMinutes: 35, type: 'video', order: 2 },
      ]},
    ],
    format: 'live', status: 'published', enrolledStudentIds: ['stu-4', 'stu-6', 'stu-8', 'stu-11'],
    createdAt: '2024-03-15T09:00:00Z', publishedAt: '2024-04-01T09:00:00Z',
  },
  {
    id: 'crs-5', title: 'Marketplace Seller Excellence', description: 'Advanced course for marketplace sellers covering account health, advertising, brand building, and international expansion.', category: 'E-Commerce Management', instructorId: 'ins-1', durationWeeks: 8, fee: 8999,
    learningObjectives: ['Maintain healthy seller metrics', 'Scale with sponsored advertising', 'Build a brand on marketplaces', 'Expand internationally'],
    prerequisites: ['Active seller account', 'E-Commerce Operations Masterclass recommended'],
    modules: [
      { id: 'mod-5-1', title: 'Account Health', order: 1, lessons: [
        { id: 'les-mk-1', title: 'Seller Performance Metrics', durationMinutes: 38, type: 'video', order: 1 },
      ]},
    ],
    format: 'recorded', status: 'draft', enrolledStudentIds: [],
    createdAt: '2024-09-01T09:00:00Z',
  },
  {
    id: 'crs-6', title: 'Social Media Marketing Pro', description: 'Advanced social media strategies including influencer marketing, community building, and content creation workflows.', category: 'Digital Marketing', instructorId: 'ins-2', durationWeeks: 10, fee: 11999,
    learningObjectives: ['Build influencer campaigns', 'Create viral content frameworks', 'Manage multi-platform strategies', 'Measure social ROI'],
    prerequisites: ['Digital Marketing Certification or equivalent'],
    modules: [
      { id: 'mod-6-1', title: 'Influencer Marketing', order: 1, lessons: [
        { id: 'les-sm-1', title: 'Finding the Right Influencers', durationMinutes: 32, type: 'video', order: 1 },
      ]},
    ],
    format: 'hybrid', status: 'published', enrolledStudentIds: ['stu-7', 'stu-9'],
    createdAt: '2024-04-01T09:00:00Z', publishedAt: '2024-04-15T09:00:00Z',
  },
  {
    id: 'crs-7', title: 'Startup Launchpad', description: 'From idea to launch — validate, build, fund, and scale your startup with frameworks used by successful founders.', category: 'Entrepreneurship', instructorId: 'ins-5', durationWeeks: 12, fee: 14999,
    learningObjectives: ['Validate startup ideas', 'Build an MVP', 'Pitch to investors', 'Scale operations'],
    prerequisites: ['Entrepreneurial mindset', 'Basic business knowledge'],
    modules: [
      { id: 'mod-7-1', title: 'Idea Validation', order: 1, lessons: [
        { id: 'les-st-1', title: 'Problem-Solution Fit', durationMinutes: 45, type: 'video', order: 1 },
      ]},
    ],
    format: 'live', status: 'archived', enrolledStudentIds: ['stu-12'],
    createdAt: '2023-09-01T09:00:00Z', publishedAt: '2023-09-15T09:00:00Z',
  },
];

export const students: Student[] = [
  { id: 'stu-1', studentId: 'IIECM20240001', fullName: 'Aarav Patel', email: 'aarav.patel@gmail.com', phone: '+91 90000 11111', educationLevel: "Bachelor's", qualification: 'B.Com', preferredCategory: 'E-Commerce Management', subscriptionPlan: 'premium', subscriptionStatus: 'active', subscriptionStart: '2024-04-01', subscriptionExpiry: '2025-04-01', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'completed', enrolledCourseIds: ['crs-1', 'crs-2'], createdAt: '2024-04-01T10:00:00Z', city: 'Mumbai', country: 'India' },
  { id: 'stu-2', studentId: 'IIECM20240002', fullName: 'Diya Sharma', email: 'diya.sharma@gmail.com', phone: '+91 90000 22222', educationLevel: "Master's", qualification: 'MBA', preferredCategory: 'E-Commerce Management', subscriptionPlan: 'premium', subscriptionStatus: 'active', subscriptionStart: '2024-04-05', subscriptionExpiry: '2025-04-05', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'in_progress', enrolledCourseIds: ['crs-1', 'crs-3'], createdAt: '2024-04-05T10:00:00Z', city: 'Delhi', country: 'India' },
  { id: 'stu-3', studentId: 'IIECM20240003', fullName: 'Arjun Gupta', email: 'arjun.gupta@gmail.com', phone: '+91 90000 33333', educationLevel: "Bachelor's", qualification: 'B.Tech', preferredCategory: 'Digital Marketing', subscriptionPlan: 'basic', subscriptionStatus: 'active', subscriptionStart: '2024-05-01', subscriptionExpiry: '2024-11-01', accountStatus: 'active', resumeUploaded: false, careerGuidanceStatus: 'not_started', enrolledCourseIds: ['crs-1', 'crs-2'], createdAt: '2024-05-01T10:00:00Z', city: 'Bangalore', country: 'India' },
  { id: 'stu-4', studentId: 'IIECM20240004', fullName: 'Saanvi Iyer', email: 'saanvi.iyer@gmail.com', phone: '+91 90000 44444', educationLevel: "Master's", qualification: 'MSc Statistics', preferredCategory: 'Business Analytics', subscriptionPlan: 'enterprise', subscriptionStatus: 'active', subscriptionStart: '2024-05-10', subscriptionExpiry: '2025-05-10', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'completed', enrolledCourseIds: ['crs-2', 'crs-4'], createdAt: '2024-05-10T10:00:00Z', city: 'Chennai', country: 'India' },
  { id: 'stu-5', studentId: 'IIECM20240005', fullName: 'Vihaan Joshi', email: 'vihaan.joshi@gmail.com', phone: '+91 90000 55555', educationLevel: "Bachelor's", qualification: 'BBA', preferredCategory: 'Supply Chain', subscriptionPlan: 'basic', subscriptionStatus: 'expired', subscriptionStart: '2023-11-01', subscriptionExpiry: '2024-05-01', accountStatus: 'inactive', resumeUploaded: false, careerGuidanceStatus: 'not_started', enrolledCourseIds: ['crs-1', 'crs-3'], createdAt: '2024-05-15T10:00:00Z', city: 'Pune', country: 'India' },
  { id: 'stu-6', studentId: 'IIECM20240006', fullName: 'Ananya Bose', email: 'ananya.bose@gmail.com', phone: '+91 90000 66666', educationLevel: "Master's", qualification: 'MBA Marketing', preferredCategory: 'Digital Marketing', subscriptionPlan: 'premium', subscriptionStatus: 'active', subscriptionStart: '2024-06-01', subscriptionExpiry: '2025-06-01', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'in_progress', enrolledCourseIds: ['crs-2', 'crs-4'], createdAt: '2024-06-01T10:00:00Z', city: 'Kolkata', country: 'India' },
  { id: 'stu-7', studentId: 'IIECM20240007', fullName: 'Reyansh Nair', email: 'reyansh.nair@gmail.com', phone: '+91 90000 77777', educationLevel: "Bachelor's", qualification: 'B.A Economics', preferredCategory: 'Digital Marketing', subscriptionPlan: 'basic', subscriptionStatus: 'active', subscriptionStart: '2024-06-10', subscriptionExpiry: '2024-12-10', accountStatus: 'active', resumeUploaded: false, careerGuidanceStatus: 'not_started', enrolledCourseIds: ['crs-2', 'crs-6'], createdAt: '2024-06-10T10:00:00Z', city: 'Kochi', country: 'India' },
  { id: 'stu-8', studentId: 'IIECM20240008', fullName: 'Ishita Verma', email: 'ishita.verma@gmail.com', phone: '+91 90000 88888', educationLevel: "Master's", qualification: 'M.Com', preferredCategory: 'E-Commerce Management', subscriptionPlan: 'premium', subscriptionStatus: 'pending', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'in_progress', enrolledCourseIds: ['crs-1', 'crs-4'], createdAt: '2024-09-01T10:00:00Z', city: 'Jaipur', country: 'India' },
  { id: 'stu-9', studentId: 'IIECM20240009', fullName: 'Kabir Khanna', email: 'kabir.khanna@gmail.com', phone: '+91 90000 99999', educationLevel: "Bachelor's", qualification: 'B.Tech CSE', preferredCategory: 'Digital Marketing', subscriptionPlan: 'basic', subscriptionStatus: 'active', subscriptionStart: '2024-09-15', subscriptionExpiry: '2025-03-15', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'not_started', enrolledCourseIds: ['crs-2', 'crs-6'], createdAt: '2024-09-15T10:00:00Z', city: 'Chandigarh', country: 'India' },
  { id: 'stu-10', studentId: 'IIECM20240010', fullName: 'Myra Reddy', email: 'myra.reddy@gmail.com', phone: '+91 90001 00000', educationLevel: "Master's", qualification: 'MBA Operations', preferredCategory: 'Supply Chain', subscriptionPlan: 'free', subscriptionStatus: 'pending', accountStatus: 'suspended', resumeUploaded: false, careerGuidanceStatus: 'not_started', enrolledCourseIds: ['crs-3'], createdAt: '2024-10-01T10:00:00Z', city: 'Hyderabad', country: 'India' },
  { id: 'stu-11', studentId: 'IIECM20240011', fullName: 'Advait Menon', email: 'advait.menon@gmail.com', phone: '+91 90001 11111', educationLevel: "Bachelor's", qualification: 'B.Sc IT', preferredCategory: 'Business Analytics', subscriptionPlan: 'premium', subscriptionStatus: 'active', subscriptionStart: '2024-10-10', subscriptionExpiry: '2025-10-10', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'completed', enrolledCourseIds: ['crs-4'], createdAt: '2024-10-10T10:00:00Z', city: 'Thiruvananthapuram', country: 'India' },
  { id: 'stu-12', studentId: 'IIECM20240012', fullName: 'Sara Kapoor', email: 'sara.kapoor@gmail.com', phone: '+91 90001 22222', educationLevel: "Master's", qualification: 'MA Economics', preferredCategory: 'Entrepreneurship', subscriptionPlan: 'enterprise', subscriptionStatus: 'active', subscriptionStart: '2024-10-20', subscriptionExpiry: '2025-10-20', accountStatus: 'active', resumeUploaded: true, careerGuidanceStatus: 'in_progress', enrolledCourseIds: ['crs-7'], createdAt: '2024-10-20T10:00:00Z', city: 'Lucknow', country: 'India' },
];

export const payments: Payment[] = [
  { id: 'pay-1', transactionRef: 'TXN20240401001', studentId: 'stu-1', studentName: 'Aarav Patel', courseId: 'crs-1', courseName: 'E-Commerce Operations Masterclass', subscriptionPlan: 'premium', amount: 9999, paymentMethod: 'razorpay', status: 'verified', paymentDate: '2024-04-01T11:00:00Z', verifiedBy: 'Dr. Priya Sharma', subscriptionStart: '2024-04-01', subscriptionExpiry: '2025-04-01' },
  { id: 'pay-2', transactionRef: 'TXN20240405002', studentId: 'stu-2', studentName: 'Diya Sharma', courseId: 'crs-1', courseName: 'E-Commerce Operations Masterclass', subscriptionPlan: 'premium', amount: 9999, paymentMethod: 'upi', status: 'verified', paymentDate: '2024-04-05T11:00:00Z', verifiedBy: 'Dr. Priya Sharma', subscriptionStart: '2024-04-05', subscriptionExpiry: '2025-04-05' },
  { id: 'pay-3', transactionRef: 'TXN20240501003', studentId: 'stu-3', studentName: 'Arjun Gupta', courseId: 'crs-2', courseName: 'Digital Marketing Certification', subscriptionPlan: 'basic', amount: 4999, paymentMethod: 'card', status: 'verified', paymentDate: '2024-05-01T11:00:00Z', verifiedBy: 'Dr. Priya Sharma', subscriptionStart: '2024-05-01', subscriptionExpiry: '2024-11-01' },
  { id: 'pay-4', transactionRef: 'TXN20240510004', studentId: 'stu-4', studentName: 'Saanvi Iyer', courseId: 'crs-4', courseName: 'Business Analytics with Python', subscriptionPlan: 'enterprise', amount: 24999, paymentMethod: 'bank_transfer', status: 'verified', paymentDate: '2024-05-10T11:00:00Z', verifiedBy: 'Dr. Priya Sharma', subscriptionStart: '2024-05-10', subscriptionExpiry: '2025-05-10' },
  { id: 'pay-5', transactionRef: 'TXN20240601005', studentId: 'stu-6', studentName: 'Ananya Bose', courseId: 'crs-2', courseName: 'Digital Marketing Certification', subscriptionPlan: 'premium', amount: 9999, paymentMethod: 'razorpay', status: 'verified', paymentDate: '2024-06-01T11:00:00Z', verifiedBy: 'Dr. Priya Sharma', subscriptionStart: '2024-06-01', subscriptionExpiry: '2025-06-01' },
  { id: 'pay-6', transactionRef: 'TXN20240610006', studentId: 'stu-7', studentName: 'Reyansh Nair', courseId: 'crs-2', courseName: 'Digital Marketing Certification', subscriptionPlan: 'basic', amount: 4999, paymentMethod: 'upi', status: 'verified', paymentDate: '2024-06-10T11:00:00Z', verifiedBy: 'Dr. Priya Sharma', subscriptionStart: '2024-06-10', subscriptionExpiry: '2024-12-10' },
  { id: 'pay-7', transactionRef: 'TXN20240901007', studentId: 'stu-8', studentName: 'Ishita Verma', courseId: 'crs-1', courseName: 'E-Commerce Operations Masterclass', subscriptionPlan: 'premium', amount: 9999, paymentMethod: 'razorpay', status: 'pending', paymentDate: '2024-09-01T11:00:00Z' },
  { id: 'pay-8', transactionRef: 'TXN20240915008', studentId: 'stu-9', studentName: 'Kabir Khanna', courseId: 'crs-2', courseName: 'Digital Marketing Certification', subscriptionPlan: 'basic', amount: 4999, paymentMethod: 'card', status: 'verified', paymentDate: '2024-09-15T11:00:00Z', verifiedBy: 'Dr. Priya Sharma', subscriptionStart: '2024-09-15', subscriptionExpiry: '2025-03-15' },
  { id: 'pay-9', transactionRef: 'TXN20241010009', studentId: 'stu-11', studentName: 'Advait Menon', courseId: 'crs-4', courseName: 'Business Analytics with Python', subscriptionPlan: 'premium', amount: 9999, paymentMethod: 'bank_transfer', status: 'pending', paymentDate: '2024-10-10T11:00:00Z' },
  { id: 'pay-10', transactionRef: 'TXN20241020010', studentId: 'stu-12', studentName: 'Sara Kapoor', courseId: 'crs-7', courseName: 'Startup Launchpad', subscriptionPlan: 'enterprise', amount: 24999, paymentMethod: 'cheque', status: 'pending', paymentDate: '2024-10-20T11:00:00Z' },
  { id: 'pay-11', transactionRef: 'TXN20240501011', studentId: 'stu-5', studentName: 'Vihaan Joshi', courseId: 'crs-3', courseName: 'Supply Chain & Logistics Management', subscriptionPlan: 'basic', amount: 4999, paymentMethod: 'cash', status: 'rejected', paymentDate: '2024-05-15T11:00:00Z', rejectionReason: 'Insufficient payment proof provided' },
  { id: 'pay-12', transactionRef: 'TXN20240601012', studentId: 'stu-3', studentName: 'Arjun Gupta', courseId: 'crs-6', courseName: 'Social Media Marketing Pro', subscriptionPlan: 'basic', amount: 4999, paymentMethod: 'upi', status: 'failed', paymentDate: '2024-07-01T11:00:00Z' },
  { id: 'pay-13', transactionRef: 'TXN20240501013', studentId: 'stu-5', studentName: 'Vihaan Joshi', courseId: 'crs-1', courseName: 'E-Commerce Operations Masterclass', subscriptionPlan: 'basic', amount: 4999, paymentMethod: 'razorpay', status: 'refunded', paymentDate: '2024-05-20T11:00:00Z', refundStatus: 'completed', verifiedBy: 'Dr. Priya Sharma' },
];

export const enquiries: Enquiry[] = [
  { id: 'enq-1', enquiryId: 'ENQ202410001', studentName: 'Rohit Desai', email: 'rohit.desai@gmail.com', phone: '+91 80100 12345', educationLevel: "Bachelor's", careerInterests: ['E-Commerce', 'Digital Marketing'], preferredService: 'Premium Plan', budgetMin: 8000, budgetMax: 15000, preferredMode: 'online', source: 'website', assignedCounsellor: 'Dr. Priya Sharma', followUpDate: '2026-11-02', status: 'new', notes: 'Interested in starting within this quarter. Currently working in retail.', followUpHistory: [], createdAt: '2026-10-25T10:00:00Z' },
  { id: 'enq-2', enquiryId: 'ENQ202410002', studentName: 'Pooja Agarwal', email: 'pooja.agarwal@gmail.com', phone: '+91 80100 23456', educationLevel: "Master's", careerInterests: ['Business Analytics', 'Data Science'], preferredService: 'Enterprise Plan', budgetMin: 20000, budgetMax: 30000, preferredMode: 'hybrid', source: 'referral', assignedCounsellor: 'Dr. Priya Sharma', followUpDate: '2026-10-30', status: 'contacted', notes: 'Referred by Aarav Patel. Strong analytics background, looking for career transition.', followUpHistory: [{ id: 'fu-1', date: '2026-10-26T11:00:00Z', note: 'Initial call completed. Candidate is very interested.', by: 'Dr. Priya Sharma', outcome: 'interested' }], createdAt: '2026-10-24T10:00:00Z' },
  { id: 'enq-3', enquiryId: 'ENQ202410003', studentName: 'Karan Malhotra', email: 'karan.malhotra@gmail.com', phone: '+91 80100 34567', educationLevel: "Bachelor's", careerInterests: ['Supply Chain', 'Operations'], preferredService: 'Basic Plan', budgetMin: 3000, budgetMax: 7000, preferredMode: 'offline', source: 'social_media', assignedCounsellor: 'Dr. Priya Sharma', followUpDate: '2026-11-05', status: 'follow_up', notes: 'Wants to visit campus before enrolling.', followUpHistory: [{ id: 'fu-2', date: '2026-10-23T11:00:00Z', note: 'Sent course brochure and fee structure.', by: 'Dr. Priya Sharma', outcome: 'callback_scheduled' }, { id: 'fu-3', date: '2026-10-25T14:00:00Z', note: 'Campus visit scheduled for Nov 5.', by: 'Dr. Priya Sharma', outcome: 'callback_scheduled' }], createdAt: '2026-10-22T10:00:00Z' },
  { id: 'enq-4', enquiryId: 'ENQ202410004', studentName: 'Nisha Pillai', email: 'nisha.pillai@gmail.com', phone: '+91 80100 45678', educationLevel: "Master's", careerInterests: ['Entrepreneurship', 'Startup'], preferredService: 'Premium Plan', budgetMin: 10000, budgetMax: 20000, preferredMode: 'online', source: 'phone', assignedCounsellor: 'Dr. Priya Sharma', followUpDate: '2026-10-28', status: 'converted', notes: 'Successfully enrolled in Startup Launchpad course.', followUpHistory: [{ id: 'fu-4', date: '2026-10-20T11:00:00Z', note: 'Discussed entrepreneurship pathway.', by: 'Dr. Priya Sharma', outcome: 'interested' }, { id: 'fu-5', date: '2026-10-22T15:00:00Z', note: 'Payment received, enrolled in course.', by: 'Dr. Priya Sharma', outcome: 'converted' }], createdAt: '2026-10-18T10:00:00Z' },
  { id: 'enq-5', enquiryId: 'ENQ202410005', studentName: 'Aditya Saxena', email: 'aditya.saxena@gmail.com', phone: '+91 80100 56789', educationLevel: "Bachelor's", careerInterests: ['Digital Marketing', 'Content Creation'], preferredService: 'Basic Plan', budgetMin: 4000, budgetMax: 8000, preferredMode: 'online', source: 'email', assignedCounsellor: 'Dr. Priya Sharma', followUpDate: '2026-11-10', status: 'closed', notes: 'Decided to go with another institute. May revisit in future.', followUpHistory: [{ id: 'fu-6', date: '2026-10-15T11:00:00Z', note: 'Candidate chose competitor due to lower pricing.', by: 'Dr. Priya Sharma', outcome: 'not_interested' }], createdAt: '2026-10-14T10:00:00Z' },
  { id: 'enq-6', enquiryId: 'ENQ202410006', studentName: 'Tara Krishnan', email: 'tara.krishnan@gmail.com', phone: '+91 80100 67890', educationLevel: "Master's", careerInterests: ['Government Exams', 'Banking'], preferredService: 'Premium Plan', budgetMin: 8000, budgetMax: 15000, preferredMode: 'hybrid', source: 'walk_in', assignedCounsellor: 'Dr. Priya Sharma', followUpDate: '2026-11-01', status: 'new', notes: 'Preparing for SBI PO exam. Looking for structured coaching.', followUpHistory: [], createdAt: '2026-10-27T10:00:00Z' },
];

export const assessmentCategories: AssessmentCategory[] = [
  { id: 'acat-1', name: 'E-Commerce Fundamentals', description: 'Core concepts of e-commerce operations', questionCount: 25 },
  { id: 'acat-2', name: 'Digital Marketing', description: 'SEO, SEM, and social media marketing', questionCount: 40 },
  { id: 'acat-3', name: 'Supply Chain', description: 'Logistics and inventory management', questionCount: 20 },
  { id: 'acat-4', name: 'Analytics', description: 'Data analysis and interpretation', questionCount: 30 },
];

export const questions: Question[] = [
  { id: 'q-1', questionText: 'What does SKU stand for in e-commerce?', options: [{ id: 'o-1', text: 'Stock Keeping Unit', isCorrect: true }, { id: 'o-2', text: 'Sales Key Unit', isCorrect: false }, { id: 'o-3', text: 'Store Keeper Utility', isCorrect: false }, { id: 'o-4', text: 'Stock Key Update', isCorrect: false }], marks: 2, type: 'mcq' },
  { id: 'q-2', questionText: 'Which metric measures the percentage of visitors who make a purchase?', options: [{ id: 'o-5', text: 'CTR', isCorrect: false }, { id: 'o-6', text: 'Conversion Rate', isCorrect: true }, { id: 'o-7', text: 'Bounce Rate', isCorrect: false }, { id: 'o-8', text: 'CAC', isCorrect: false }], marks: 2, type: 'mcq' },
  { id: 'q-3', questionText: 'SEO stands for Search Engine Optimization.', options: [{ id: 'o-9', text: 'True', isCorrect: true }, { id: 'o-10', text: 'False', isCorrect: false }], marks: 1, type: 'true_false' },
  { id: 'q-4', questionText: 'What is the primary goal of A/B testing in digital marketing?', options: [{ id: 'o-11', text: 'Increase server speed', isCorrect: false }, { id: 'o-12', text: 'Compare two versions to determine performance', isCorrect: true }, { id: 'o-13', text: 'Reduce ad spend', isCorrect: false }, { id: 'o-14', text: 'Add more keywords', isCorrect: false }], marks: 3, type: 'mcq' },
  { id: 'q-5', questionText: 'In supply chain, what does JIT stand for?', options: [{ id: 'o-15', text: 'Just In Time', isCorrect: true }, { id: 'o-16', text: 'Joint Inventory Tracking', isCorrect: false }, { id: 'o-17', text: 'Justified Inventory Target', isCorrect: false }, { id: 'o-18', text: 'Job Inventory Transfer', isCorrect: false }], marks: 2, type: 'mcq' },
];

export const assessments: Assessment[] = [
  { id: 'asm-1', title: 'E-Commerce Fundamentals Quiz', description: 'Test knowledge of basic e-commerce concepts', categoryId: 'acat-1', type: 'mcq', totalMarks: 20, passingMarks: 12, durationMinutes: 30, status: 'completed', questionIds: ['q-1', 'q-2'], assignedStudentIds: ['stu-1', 'stu-2', 'stu-3'], assignedCourseIds: ['crs-1'], createdBy: 'Dr. Priya Sharma', createdAt: '2024-05-01T09:00:00Z', scheduledAt: '2024-05-15T14:00:00Z' },
  { id: 'asm-2', title: 'Digital Marketing Mid-Term', description: 'Comprehensive assessment on SEO, SEM, and content marketing', categoryId: 'acat-2', type: 'mcq', totalMarks: 50, passingMarks: 30, durationMinutes: 60, status: 'active', questionIds: ['q-3', 'q-4'], assignedStudentIds: ['stu-1', 'stu-3', 'stu-6', 'stu-7', 'stu-9'], assignedCourseIds: ['crs-2'], createdBy: 'Dr. Priya Sharma', createdAt: '2024-06-01T09:00:00Z', scheduledAt: '2026-11-05T14:00:00Z' },
  { id: 'asm-3', title: 'Supply Chain Concepts', description: 'Assessment on logistics and inventory management', categoryId: 'acat-3', type: 'mcq', totalMarks: 30, passingMarks: 18, durationMinutes: 45, status: 'scheduled', questionIds: ['q-5'], assignedStudentIds: ['stu-2', 'stu-5'], assignedCourseIds: ['crs-3'], createdBy: 'Dr. Priya Sharma', createdAt: '2024-07-01T09:00:00Z', scheduledAt: '2026-11-10T14:00:00Z' },
  { id: 'asm-4', title: 'Analytics Final Project', description: 'Capstone project evaluating data analysis skills', categoryId: 'acat-4', type: 'project', totalMarks: 100, passingMarks: 60, durationMinutes: 0, status: 'draft', questionIds: [], assignedStudentIds: [], assignedCourseIds: ['crs-4'], createdBy: 'Dr. Priya Sharma', createdAt: '2024-08-01T09:00:00Z' },
];

export const assessmentResults: AssessmentResult[] = [
  { id: 'ar-1', assessmentId: 'asm-1', assessmentTitle: 'E-Commerce Fundamentals Quiz', studentId: 'stu-1', studentName: 'Aarav Patel', score: 18, totalMarks: 20, percentage: 90, passed: true, completedAt: '2024-05-15T14:30:00Z' },
  { id: 'ar-2', assessmentId: 'asm-1', assessmentTitle: 'E-Commerce Fundamentals Quiz', studentId: 'stu-2', studentName: 'Diya Sharma', score: 16, totalMarks: 20, percentage: 80, passed: true, completedAt: '2024-05-15T14:35:00Z' },
  { id: 'ar-3', assessmentId: 'asm-1', assessmentTitle: 'E-Commerce Fundamentals Quiz', studentId: 'stu-3', studentName: 'Arjun Gupta', score: 11, totalMarks: 20, percentage: 55, passed: false, completedAt: '2024-05-15T14:40:00Z' },
];

export const careerAppointments: CareerAppointment[] = [
  { id: 'ca-1', studentId: 'stu-2', studentName: 'Diya Sharma', counsellor: 'Dr. Priya Sharma', type: 'career_guidance', scheduledAt: '2026-11-03T15:00:00Z', status: 'scheduled', notes: 'Focus on e-commerce career pathways' },
  { id: 'ca-2', studentId: 'stu-6', studentName: 'Ananya Bose', counsellor: 'Dr. Priya Sharma', type: 'resume_review', scheduledAt: '2026-10-29T14:00:00Z', status: 'scheduled' },
  { id: 'ca-3', studentId: 'stu-1', studentName: 'Aarav Patel', counsellor: 'Dr. Priya Sharma', type: 'mock_interview', scheduledAt: '2026-10-26T16:00:00Z', status: 'completed', notes: 'Excellent performance on marketplace scenario questions' },
  { id: 'ca-4', studentId: 'stu-8', studentName: 'Ishita Verma', counsellor: 'Dr. Priya Sharma', type: 'career_guidance', scheduledAt: '2026-10-25T15:00:00Z', status: 'no_show' },
];

export const careerActionPlans: CareerActionPlan[] = [
  { id: 'cap-1', studentId: 'stu-1', studentName: 'Aarav Patel', goals: ['Secure e-commerce manager role within 6 months', 'Complete advanced marketplace certification'], milestones: [{ id: 'm-1', title: 'Complete E-Commerce Operations course', targetDate: '2024-10-01', completed: true }, { id: 'm-2', title: 'Build portfolio project', targetDate: '2024-12-01', completed: false }, { id: 'm-3', title: 'Apply for 10 e-commerce roles', targetDate: '2025-01-01', completed: false }], createdAt: '2024-05-01T10:00:00Z' },
  { id: 'cap-2', studentId: 'stu-4', studentName: 'Saanvi Iyer', goals: ['Transition to data analyst role', 'Master Python for analytics'], milestones: [{ id: 'm-4', title: 'Complete Analytics with Python course', targetDate: '2024-11-01', completed: true }, { id: 'm-5', title: 'Complete 3 real-world data projects', targetDate: '2025-01-01', completed: false }], createdAt: '2024-06-01T10:00:00Z' },
];

export const resources: Resource[] = [
  { id: 'res-1', title: 'E-Commerce Operations Handbook', description: 'Comprehensive guide covering marketplace operations, seller best practices, and growth strategies.', type: 'pdf', category: 'study_material', fileSize: '4.2 MB', visibility: 'enrolled', uploadedBy: 'Prof. Rajesh Kumar', createdAt: '2024-03-20T10:00:00Z', downloadCount: 156 },
  { id: 'res-2', title: 'SEO Checklist 2026', description: 'Updated on-page and technical SEO checklist with latest search engine guidelines.', type: 'pdf', category: 'career', fileSize: '1.1 MB', visibility: 'public', uploadedBy: 'Dr. Anjali Mehta', createdAt: '2024-04-10T10:00:00Z', downloadCount: 340 },
  { id: 'res-3', title: 'Supply Chain Case Studies', description: 'Real-world case studies from Flipkart, BigBasket, and Delhivery.', type: 'document', category: 'course', fileSize: '2.8 MB', visibility: 'enrolled', uploadedBy: 'Mr. Vikram Singh', createdAt: '2024-03-28T10:00:00Z', downloadCount: 89 },
  { id: 'res-4', title: 'Python for Analytics — Starter Notebook', description: 'Jupyter notebook with beginner exercises for data analysis.', type: 'document', category: 'study_material', fileSize: '850 KB', visibility: 'enrolled', uploadedBy: 'Ms. Kavya Reddy', createdAt: '2024-04-15T10:00:00Z', downloadCount: 210 },
  { id: 'res-5', title: 'UPSC Civil Services Exam Pattern Guide', description: 'Complete guide to UPSC exam structure, syllabus, and preparation strategy.', type: 'pdf', category: 'government_exam', fileSize: '3.5 MB', visibility: 'public', uploadedBy: 'Dr. Priya Sharma', createdAt: '2024-05-01T10:00:00Z', downloadCount: 520 },
  { id: 'res-6', title: 'Resume Templates for E-Commerce Roles', description: 'ATS-friendly resume templates for e-commerce and digital marketing professionals.', type: 'document', category: 'career', fileSize: '1.5 MB', visibility: 'public', uploadedBy: 'Dr. Priya Sharma', createdAt: '2024-05-10T10:00:00Z', downloadCount: 180 },
  { id: 'res-7', title: 'Google Ads Tutorial Video', description: 'Step-by-step video tutorial on setting up and optimizing Google Ads campaigns.', type: 'video', category: 'course', visibility: 'enrolled', uploadedBy: 'Dr. Anjali Mehta', createdAt: '2024-04-20T10:00:00Z', downloadCount: 95 },
  { id: 'res-8', title: 'SBI PO Exam Preparation Material', description: 'Quantitative aptitude, reasoning, and English language preparation for SBI PO.', type: 'pdf', category: 'government_exam', fileSize: '5.0 MB', visibility: 'enrolled', uploadedBy: 'Dr. Priya Sharma', createdAt: '2024-06-01T10:00:00Z', downloadCount: 410 },
];

export const notifications: AppNotification[] = [
  { id: 'n-1', title: 'New payment verification required', message: 'Ishita Verma submitted a payment of ₹9,999 for E-Commerce Operations Masterclass.', type: 'payment', priority: 'high', read: false, createdAt: '2026-10-27T08:00:00Z', actionUrl: '/payments' },
  { id: 'n-2', title: 'New student enquiry', message: 'Tara Krishnan submitted an enquiry for Government Exam preparation.', type: 'student', priority: 'medium', read: false, createdAt: '2026-10-27T07:00:00Z', actionUrl: '/enquiries' },
  { id: 'n-3', title: 'Live class tomorrow', message: 'Business Analytics with Python — Module 2 live session at 3:00 PM.', type: 'class', priority: 'high', read: false, createdAt: '2026-10-26T16:00:00Z', actionUrl: '/courses' },
  { id: 'n-4', title: 'Assessment completed', message: 'Aarav Patel scored 90% on E-Commerce Fundamentals Quiz.', type: 'student', priority: 'low', read: true, createdAt: '2024-05-15T15:00:00Z' },
  { id: 'n-5', title: 'Course published', message: 'Social Media Marketing Pro is now live and open for enrollment.', type: 'course', priority: 'medium', read: true, createdAt: '2024-04-15T10:00:00Z' },
  { id: 'n-6', title: 'Instructor account deactivated', message: 'Mr. Arjun Nair has been set to inactive. Assigned courses need reassignment.', type: 'instructor', priority: 'high', read: false, createdAt: '2026-10-25T14:00:00Z' },
  { id: 'n-7', title: 'Payment refund processed', message: 'Vihaan Joshi refund of ₹4,999 has been completed.', type: 'payment', priority: 'medium', read: true, createdAt: '2024-05-20T16:00:00Z' },
];

export const activityLogs: ActivityLog[] = [
  { id: 'act-1', adminName: 'Dr. Priya Sharma', action: 'Verified payment', target: 'TXN20240915008 — Kabir Khanna', timestamp: '2026-10-27T09:15:00Z' },
  { id: 'act-2', adminName: 'Dr. Priya Sharma', action: 'Updated course', target: 'Digital Marketing Certification', timestamp: '2026-10-26T14:30:00Z' },
  { id: 'act-3', adminName: 'Dr. Priya Sharma', action: 'Deactivated instructor', target: 'Mr. Arjun Nair', timestamp: '2026-10-25T14:00:00Z' },
  { id: 'act-4', adminName: 'Dr. Priya Sharma', action: 'Added student', target: 'Sara Kapoor (IIECM20240012)', timestamp: '2024-10-20T10:30:00Z' },
  { id: 'act-5', adminName: 'Dr. Priya Sharma', action: 'Converted enquiry', target: 'ENQ202410004 — Nisha Pillai', timestamp: '2024-10-22T15:30:00Z' },
  { id: 'act-6', adminName: 'Dr. Priya Sharma', action: 'Published course', target: 'Social Media Marketing Pro', timestamp: '2024-04-15T10:15:00Z' },
];

export const liveClasses: LiveClass[] = [
  { id: 'lc-1', title: 'E-Commerce Operations — Live Q&A', courseId: 'crs-1', courseName: 'E-Commerce Operations Masterclass', instructorId: 'ins-1', instructorName: 'Prof. Rajesh Kumar', scheduledAt: '2026-10-29T15:00:00Z', durationMinutes: 60, status: 'upcoming', meetingLink: 'https://meet.iiecm.org/room-1' },
  { id: 'lc-2', title: 'Digital Marketing — Campaign Workshop', courseId: 'crs-2', courseName: 'Digital Marketing Certification', instructorId: 'ins-2', instructorName: 'Dr. Anjali Mehta', scheduledAt: '2026-10-30T16:00:00Z', durationMinutes: 90, status: 'upcoming', meetingLink: 'https://meet.iiecm.org/room-2' },
  { id: 'lc-3', title: 'Analytics with Python — Pandas Deep Dive', courseId: 'crs-4', courseName: 'Business Analytics with Python', instructorId: 'ins-4', instructorName: 'Ms. Kavya Reddy', scheduledAt: '2026-10-28T17:00:00Z', durationMinutes: 75, status: 'upcoming', meetingLink: 'https://meet.iiecm.org/room-3' },
  { id: 'lc-4', title: 'Supply Chain — Case Study Discussion', courseId: 'crs-3', courseName: 'Supply Chain & Logistics Management', instructorId: 'ins-3', instructorName: 'Mr. Vikram Singh', scheduledAt: '2026-10-25T15:00:00Z', durationMinutes: 60, status: 'completed' },
];

export const dashboardEnrolmentChart = [
  { month: 'Apr', enrolments: 4, revenue: 24997 },
  { month: 'May', enrolments: 3, revenue: 39997 },
  { month: 'Jun', enrolments: 2, revenue: 14998 },
  { month: 'Jul', enrolments: 1, revenue: 4999 },
  { month: 'Aug', enrolments: 0, revenue: 0 },
  { month: 'Sep', enrolments: 3, revenue: 24997 },
  { month: 'Oct', enrolments: 3, revenue: 39997 },
];


export function calculateMonthlyMetrics(studentList: Student[], paymentList: Payment[]) {
  const months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
  const monthData: Record<string, { enrolments: number; revenue: number }> = {
    Apr: { enrolments: 0, revenue: 0 },
    May: { enrolments: 0, revenue: 0 },
    Jun: { enrolments: 0, revenue: 0 },
    Jul: { enrolments: 0, revenue: 0 },
    Aug: { enrolments: 0, revenue: 0 },
    Sep: { enrolments: 0, revenue: 0 },
    Oct: { enrolments: 0, revenue: 0 },
  };

  studentList.forEach((s) => {
    const d = new Date(s.createdAt);
    const m = d.toLocaleString('en-US', { month: 'short' });
    if (monthData[m]) monthData[m].enrolments += 1;
  });

  paymentList.forEach((p) => {
    if (p.status === 'verified') {
      const d = new Date(p.paymentDate);
      const m = d.toLocaleString('en-US', { month: 'short' });
      if (monthData[m]) monthData[m].revenue += p.amount;
    }
  });

  return months.map((month) => ({
    month,
    enrolments: monthData[month].enrolments,
    revenue: monthData[month].revenue,
  }));
}
