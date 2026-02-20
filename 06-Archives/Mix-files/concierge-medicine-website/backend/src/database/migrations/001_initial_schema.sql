-- Create UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ENUM types
CREATE TYPE user_role AS ENUM ('PATIENT', 'PHYSICIAN', 'ADMIN');
CREATE TYPE membership_status AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'CANCELLED');
CREATE TYPE appointment_type AS ENUM ('IN_PERSON', 'TELEMEDICINE', 'PHONE');
CREATE TYPE appointment_status AS ENUM ('SCHEDULED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW');
CREATE TYPE medical_record_type AS ENUM ('VISIT_NOTE', 'TEST_RESULT', 'PRESCRIPTION', 'LAB_REPORT', 'IMAGING');
CREATE TYPE payment_method AS ENUM ('CREDIT_CARD', 'DEBIT_CARD', 'ACH');
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED');
CREATE TYPE telemedicine_status AS ENUM ('PENDING', 'ACTIVE', 'COMPLETED', 'FAILED');

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  date_of_birth DATE,
  address TEXT,
  role user_role NOT NULL DEFAULT 'PATIENT',
  mfa_enabled BOOLEAN DEFAULT FALSE,
  mfa_secret VARCHAR(255),
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_deleted_at ON users(deleted_at);

-- Membership tiers table
CREATE TABLE membership_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  monthly_price DECIMAL(10, 2) NOT NULL,
  annual_price DECIMAL(10, 2) NOT NULL,
  appointments_per_year INTEGER NOT NULL,
  telemedicine_included BOOLEAN DEFAULT TRUE,
  response_time_hours INTEGER NOT NULL,
  includes_preventive_care BOOLEAN DEFAULT TRUE,
  includes_chronic_disease_management BOOLEAN DEFAULT TRUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Patients table
CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE,
  membership_tier_id UUID NOT NULL,
  membership_status membership_status DEFAULT 'INACTIVE',
  membership_start_date DATE,
  membership_end_date DATE,
  emergency_contact_name VARCHAR(255),
  emergency_contact_phone VARCHAR(20),
  insurance_provider VARCHAR(255),
  insurance_policy_number VARCHAR(255),
  allergies TEXT[],
  current_medications TEXT[],
  medical_conditions TEXT[],
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (membership_tier_id) REFERENCES membership_tiers(id)
);

CREATE INDEX idx_patients_user_id ON patients(user_id);
CREATE INDEX idx_patients_membership_status ON patients(membership_status);

-- Physicians table
CREATE TABLE physicians (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE,
  specialties TEXT[],
  years_of_experience INTEGER,
  professional_certifications TEXT[],
  license_number VARCHAR(255),
  bio TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_physicians_user_id ON physicians(user_id);

-- Appointments table
CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL,
  physician_id UUID NOT NULL,
  appointment_type appointment_type NOT NULL,
  reason_for_visit TEXT,
  scheduled_start_time TIMESTAMP NOT NULL,
  scheduled_end_time TIMESTAMP NOT NULL,
  status appointment_status DEFAULT 'SCHEDULED',
  notes TEXT,
  reminders_sent BOOLEAN[] DEFAULT ARRAY[FALSE, FALSE, FALSE],
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  FOREIGN KEY (physician_id) REFERENCES physicians(id) ON DELETE CASCADE
);

CREATE INDEX idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX idx_appointments_physician_id ON appointments(physician_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_scheduled_start_time ON appointments(scheduled_start_time);

-- Medical records table
CREATE TABLE medical_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL,
  record_type medical_record_type NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  file_url VARCHAR(500),
  file_size INTEGER,
  mime_type VARCHAR(100),
  uploaded_by UUID NOT NULL,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  is_shared BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES users(id)
);

CREATE INDEX idx_medical_records_patient_id ON medical_records(patient_id);
CREATE INDEX idx_medical_records_record_type ON medical_records(record_type);
CREATE INDEX idx_medical_records_uploaded_by ON medical_records(uploaded_by);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID NOT NULL,
  recipient_id UUID NOT NULL,
  subject VARCHAR(255),
  body TEXT NOT NULL,
  attachments VARCHAR(500)[],
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_recipient_id ON messages(recipient_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- Invoices table
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  due_date DATE NOT NULL,
  paid_date DATE,
  status VARCHAR(50) DEFAULT 'PENDING',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
);

CREATE INDEX idx_invoices_patient_id ON invoices(patient_id);
CREATE INDEX idx_invoices_status ON invoices(status);

-- Payments table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  payment_method payment_method NOT NULL,
  stripe_payment_intent_id VARCHAR(255),
  status payment_status DEFAULT 'PENDING',
  invoice_id UUID,
  processed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id)
);

CREATE INDEX idx_payments_patient_id ON payments(patient_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_stripe_payment_intent_id ON payments(stripe_payment_intent_id);

-- Telemedicine sessions table
CREATE TABLE telemedicine_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID NOT NULL UNIQUE,
  session_token VARCHAR(500),
  agora_channel_name VARCHAR(255),
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  duration INTEGER,
  recording_url VARCHAR(500),
  status telemedicine_status DEFAULT 'PENDING',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
);

CREATE INDEX idx_telemedicine_sessions_appointment_id ON telemedicine_sessions(appointment_id);
CREATE INDEX idx_telemedicine_sessions_status ON telemedicine_sessions(status);

-- Audit logs table
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  action VARCHAR(255) NOT NULL,
  resource_type VARCHAR(100),
  resource_id UUID,
  details JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_physicians_updated_at BEFORE UPDATE ON physicians
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medical_records_updated_at BEFORE UPDATE ON medical_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_telemedicine_sessions_updated_at BEFORE UPDATE ON telemedicine_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_membership_tiers_updated_at BEFORE UPDATE ON membership_tiers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
