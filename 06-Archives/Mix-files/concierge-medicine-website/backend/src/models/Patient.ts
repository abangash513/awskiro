import { query } from '../database/connection';
import { Patient, MembershipStatus } from '../types';

export class PatientModel {
  static async create(
    userId: string,
    membershipTierId: string,
    emergencyContactName?: string,
    emergencyContactPhone?: string,
  ): Promise<Patient> {
    const result = await query(
      `INSERT INTO patients (user_id, membership_tier_id, membership_status, emergency_contact_name, emergency_contact_phone)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, user_id, membership_tier_id, membership_status, membership_start_date, membership_end_date, emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, allergies, current_medications, medical_conditions, created_at, updated_at`,
      [userId, membershipTierId, 'INACTIVE', emergencyContactName, emergencyContactPhone],
    );

    return this.mapRow(result.rows[0]);
  }

  static async findById(id: string): Promise<Patient | null> {
    const result = await query(
      `SELECT id, user_id, membership_tier_id, membership_status, membership_start_date, membership_end_date, emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, allergies, current_medications, medical_conditions, created_at, updated_at
       FROM patients WHERE id = $1`,
      [id],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findByUserId(userId: string): Promise<Patient | null> {
    const result = await query(
      `SELECT id, user_id, membership_tier_id, membership_status, membership_start_date, membership_end_date, emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, allergies, current_medications, medical_conditions, created_at, updated_at
       FROM patients WHERE user_id = $1`,
      [userId],
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async update(id: string, updates: Partial<Patient>): Promise<Patient | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramCount = 1;

    if (updates.membershipStatus !== undefined) {
      fields.push(`membership_status = $${paramCount++}`);
      values.push(updates.membershipStatus);
    }
    if (updates.membershipStartDate !== undefined) {
      fields.push(`membership_start_date = $${paramCount++}`);
      values.push(updates.membershipStartDate);
    }
    if (updates.membershipEndDate !== undefined) {
      fields.push(`membership_end_date = $${paramCount++}`);
      values.push(updates.membershipEndDate);
    }
    if (updates.allergies !== undefined) {
      fields.push(`allergies = $${paramCount++}`);
      values.push(updates.allergies);
    }
    if (updates.currentMedications !== undefined) {
      fields.push(`current_medications = $${paramCount++}`);
      values.push(updates.currentMedications);
    }
    if (updates.medicalConditions !== undefined) {
      fields.push(`medical_conditions = $${paramCount++}`);
      values.push(updates.medicalConditions);
    }
    if (updates.insuranceProvider !== undefined) {
      fields.push(`insurance_provider = $${paramCount++}`);
      values.push(updates.insuranceProvider);
    }
    if (updates.insurancePolicyNumber !== undefined) {
      fields.push(`insurance_policy_number = $${paramCount++}`);
      values.push(updates.insurancePolicyNumber);
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const result = await query(
      `UPDATE patients SET ${fields.join(', ')} WHERE id = $${paramCount}
       RETURNING id, user_id, membership_tier_id, membership_status, membership_start_date, membership_end_date, emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, allergies, current_medications, medical_conditions, created_at, updated_at`,
      values,
    );

    return result.rows.length > 0 ? this.mapRow(result.rows[0]) : null;
  }

  static async findByMembershipStatus(status: MembershipStatus): Promise<Patient[]> {
    const result = await query(
      `SELECT id, user_id, membership_tier_id, membership_status, membership_start_date, membership_end_date, emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_policy_number, allergies, current_medications, medical_conditions, created_at, updated_at
       FROM patients WHERE membership_status = $1`,
      [status],
    );

    return result.rows.map((row) => this.mapRow(row));
  }

  private static mapRow(row: Record<string, unknown>): Patient {
    return {
      id: row.id as string,
      userId: row.user_id as string,
      membershipTierId: row.membership_tier_id as string,
      membershipStatus: row.membership_status as string,
      membershipStartDate: row.membership_start_date ? new Date(row.membership_start_date as string) : undefined,
      membershipEndDate: row.membership_end_date ? new Date(row.membership_end_date as string) : undefined,
      emergencyContactName: row.emergency_contact_name as string | undefined,
      emergencyContactPhone: row.emergency_contact_phone as string | undefined,
      insuranceProvider: row.insurance_provider as string | undefined,
      insurancePolicyNumber: row.insurance_policy_number as string | undefined,
      allergies: (row.allergies as string[]) || [],
      currentMedications: (row.current_medications as string[]) || [],
      medicalConditions: (row.medical_conditions as string[]) || [],
      createdAt: new Date(row.created_at as string),
      updatedAt: new Date(row.updated_at as string),
    };
  }
}
