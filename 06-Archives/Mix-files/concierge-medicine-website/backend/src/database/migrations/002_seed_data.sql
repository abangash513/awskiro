-- Seed membership tiers
INSERT INTO membership_tiers (name, monthly_price, annual_price, appointments_per_year, telemedicine_included, response_time_hours, includes_preventive_care, includes_chronic_disease_management, description)
VALUES
  ('BASIC', 99.00, 990.00, 4, true, 48, true, false, 'Basic membership with quarterly visits and telemedicine access'),
  ('PREMIUM', 199.00, 1990.00, 12, true, 24, true, true, 'Premium membership with monthly visits and priority access'),
  ('VIP', 399.00, 3990.00, 24, true, 4, true, true, 'VIP membership with bi-weekly visits and same-day access');

-- Seed test physician user
INSERT INTO users (email, password_hash, first_name, last_name, phone_number, date_of_birth, role)
VALUES
  ('dr.smith@concierge-medicine.com', '$2a$10$placeholder_hash_for_password123', 'John', 'Smith', '+1-555-0100', '1975-03-15', 'PHYSICIAN');

-- Seed physician profile
INSERT INTO physicians (user_id, specialties, years_of_experience, professional_certifications, license_number, bio)
SELECT id, ARRAY['Internal Medicine', 'Preventive Care'], 20, ARRAY['MD', 'Board Certified'], 'MD123456', 'Dr. Smith is a board-certified internist with 20 years of experience in personalized medicine.'
FROM users WHERE email = 'dr.smith@concierge-medicine.com';

-- Seed test patient user
INSERT INTO users (email, password_hash, first_name, last_name, phone_number, date_of_birth, role)
VALUES
  ('patient@example.com', '$2a$10$placeholder_hash_for_password123', 'Jane', 'Doe', '+1-555-0101', '1985-06-20', 'PATIENT');

-- Seed patient profile
INSERT INTO patients (user_id, membership_tier_id, membership_status, membership_start_date, emergency_contact_name, emergency_contact_phone, allergies, current_medications, medical_conditions)
SELECT u.id, mt.id, 'ACTIVE', CURRENT_DATE, 'John Doe', '+1-555-0102', ARRAY['Penicillin'], ARRAY['Lisinopril 10mg'], ARRAY['Hypertension']
FROM users u, membership_tiers mt
WHERE u.email = 'patient@example.com' AND mt.name = 'PREMIUM';

-- Seed test admin user
INSERT INTO users (email, password_hash, first_name, last_name, role)
VALUES
  ('admin@concierge-medicine.com', '$2a$10$placeholder_hash_for_password123', 'Admin', 'User', 'ADMIN');
