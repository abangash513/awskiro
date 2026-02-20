// User types
export type UserRole = 'PATIENT' | 'PHYSICIAN' | 'ADMIN';

export interface User {
  id: string;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  dateOfBirth?: Date;
  address?: string;
  role: UserRole;
  mfaEnabled: boolean;
  mfaSecret?: string;
  lastLogin?: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

// Membership types
export type MembershipStatus = 'ACTIVE' | 'INACTIVE' | 'SUSPENDED' | 'CANCELLED';

export interface MembershipTier {
  id: string;
  name: string;
  monthlyPrice: number;
  annualPrice: number;
  appointmentsPerYear: number;
  telemedicineIncluded: boolean;
  responseTimeHours: number;
  includesPreventiveCare: boolean;
  includesChronicDiseaseManagement: boolean;
  description?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Patient {
  id: string;
  userId: string;
  membershipTierId: string;
  membershipStatus: MembershipStatus;
  membershipStartDate?: Date;
  membershipEndDate?: Date;
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  insuranceProvider?: string;
  insurancePolicyNumber?: string;
  allergies: string[];
  currentMedications: string[];
  medicalConditions: string[];
  createdAt: Date;
  updatedAt: Date;
}

export interface Physician {
  id: string;
  userId: string;
  specialties: string[];
  yearsOfExperience?: number;
  professionalCertifications: string[];
  licenseNumber?: string;
  bio?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Appointment types
export type AppointmentType = 'IN_PERSON' | 'TELEMEDICINE' | 'PHONE';
export type AppointmentStatus = 'SCHEDULED' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED' | 'NO_SHOW';

export interface Appointment {
  id: string;
  patientId: string;
  physicianId: string;
  appointmentType: AppointmentType;
  reasonForVisit?: string;
  scheduledStartTime: Date;
  scheduledEndTime: Date;
  status: AppointmentStatus;
  notes?: string;
  remindersSent: boolean[];
  createdAt: Date;
  updatedAt: Date;
}

// Medical record types
export type MedicalRecordType = 'VISIT_NOTE' | 'TEST_RESULT' | 'PRESCRIPTION' | 'LAB_REPORT' | 'IMAGING';

export interface MedicalRecord {
  id: string;
  patientId: string;
  recordType: MedicalRecordType;
  title: string;
  description?: string;
  fileUrl?: string;
  fileSize?: number;
  mimeType?: string;
  uploadedBy: string;
  uploadedAt: Date;
  expiresAt?: Date;
  isShared: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Message types
export interface Message {
  id: string;
  senderId: string;
  recipientId: string;
  subject?: string;
  body: string;
  attachments: string[];
  isRead: boolean;
  readAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

// Payment types
export type PaymentMethod = 'CREDIT_CARD' | 'DEBIT_CARD' | 'ACH';
export type PaymentStatus = 'PENDING' | 'SUCCEEDED' | 'FAILED' | 'REFUNDED';

export interface Invoice {
  id: string;
  patientId: string;
  amount: number;
  currency: string;
  invoiceNumber: string;
  dueDate: Date;
  paidDate?: Date;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Payment {
  id: string;
  patientId: string;
  amount: number;
  currency: string;
  paymentMethod: PaymentMethod;
  stripePaymentIntentId?: string;
  status: PaymentStatus;
  invoiceId?: string;
  processedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

// Telemedicine types
export type TelemedicineStatus = 'PENDING' | 'ACTIVE' | 'COMPLETED' | 'FAILED';

export interface TelemedicineSession {
  id: string;
  appointmentId: string;
  sessionToken?: string;
  agoraChannelName?: string;
  startTime?: Date;
  endTime?: Date;
  duration?: number;
  recordingUrl?: string;
  status: TelemedicineStatus;
  createdAt: Date;
  updatedAt: Date;
}

// Audit log types
export interface AuditLog {
  id: string;
  userId?: string;
  action: string;
  resourceType?: string;
  resourceId?: string;
  details?: Record<string, unknown>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
}

// Request/Response types
export interface AuthRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  refreshToken: string;
  user: Omit<User, 'passwordHash' | 'mfaSecret'>;
}

export interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
    timestamp: string;
    requestId: string;
  };
}
